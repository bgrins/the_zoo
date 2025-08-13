# On-Demand Docker Functionality Analysis

## Overview

The Zoo development environment implements an on-demand Docker container startup system through a custom Caddy module (`on_demand_docker`). This analysis examines the implementation details, security implications, and potential correctness issues.

## Architecture

### 1. Core Components

- **Caddy Module**: `/core/caddy/modules/ondemanddocker/ondemanddocker.go`
- **Configuration**: Generated via `/scripts/generate-config.ts`
- **Docker Compose**: Services marked with `profiles: ["on-demand"]`

### 2. How It Works

1. **Container Profile**: Services in `docker-compose.yaml` are marked with `profiles: ["on-demand"]`
2. **Caddy Handler**: The `on_demand_docker` module intercepts HTTP requests
3. **Container Check**: Checks if the target container is running
4. **Startup Process**: If not running, starts the container and waits for it to be healthy
5. **Request Forwarding**: Once ready, forwards the request to the container

### 3. Implementation Details

#### Container Status Checking

```go
func (od *OnDemandDocker) getContainerStatus() (string, error) {
    ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
    defer cancel()
    
    cmd := exec.CommandContext(ctx, "docker", "inspect", "--format", "{{.State.Status}}", od.actualContainerName)
    output, err := cmd.Output()
    if err != nil {
        return "not found", nil
    }
    
    return strings.TrimSpace(string(output)), nil
}
```

#### Container Starting

```go
func (od *OnDemandDocker) startContainer() error {
    ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
    defer cancel()
    
    cmd := exec.CommandContext(ctx, "docker", "start", od.actualContainerName)
    if err := cmd.Run(); err != nil {
        return fmt.Errorf("failed to start container: %w", err)
    }
    
    return nil
}
```

## Security Analysis

### 1. Command Injection Vulnerabilities

**CRITICAL**: The module directly passes container names to shell commands without proper sanitization.

```go
cmd := exec.CommandContext(ctx, "docker", "inspect", "--format", "{{.State.Status}}", od.actualContainerName)
```

**Risks**:

- Container names containing shell metacharacters could lead to command injection
- No validation of `actualContainerName` before use in commands
- Multiple exec calls with user-controlled input

### 2. Container Name Resolution

The module attempts to resolve container names dynamically:

```go
func (od *OnDemandDocker) resolveContainerName() string {
    possibleNames := []string{
        fmt.Sprintf("%s-%s-1", projectName, od.ContainerName),
        fmt.Sprintf("%s_%s_1", projectName, od.ContainerName),
        od.ContainerName,
    }
    // ...
}
```

**Issues**:

- No validation of container name format
- Accepts arbitrary container names from configuration
- Could potentially start unintended containers

### 3. Privilege Escalation Potential

- The Caddy container must have Docker socket access or Docker API permissions
- Can start/stop any container visible to the Docker daemon
- No authorization checks on which containers can be managed

### 4. Resource Exhaustion

- No rate limiting on container startup attempts
- Malicious requests could trigger repeated container starts
- Cache invalidation on proxy errors could be exploited

## Correctness Issues

### 1. Race Conditions

**Container Status Caching**:

```go
var (
    statusCache = make(map[string]*cacheEntry)
    cacheMutex  sync.RWMutex
)
```

The global cache is properly protected by mutex, but there's a race between checking status and starting containers.

### 2. Health Check Logic

```go
if healthJSON == "null" || healthJSON == "<no value>" {
    // Wait a bit for the service to start up
    time.Sleep(2 * time.Second)
    return true, nil
}
```

**Issues**:

- Hardcoded 2-second wait for containers without health checks
- May return true before service is actually ready
- No configurable startup delay

### 3. Error Handling

```go
if err != nil {
    // Container might not exist
    return "not found", nil
}
```

**Problems**:

- Swallows errors and assumes container doesn't exist
- Could mask permission issues or Docker daemon problems
- No distinction between different error types

### 4. Project Name Detection

```go
func detectProjectName() (string, error) {
    hostname, err := os.Hostname()
    if err != nil {
        return "", fmt.Errorf("failed to get hostname: %w", err)
    }
    
    cmd := exec.CommandContext(ctx, "docker", "inspect", hostname, "--format", "{{index .Config.Labels \"com.docker.compose.project\"}}")
    // ...
}
```

**Issues**:

- Assumes hostname equals container ID (not always true)
- Fallback logic may select wrong containers
- No validation of detected project name

## Recommendations

### Security Improvements

1. **Input Validation**: Validate container names against a whitelist pattern
2. **Command Safety**: Use Docker SDK instead of exec commands
3. **Authorization**: Implement checks for which containers can be managed
4. **Rate Limiting**: Add request throttling for container startups

### Correctness Improvements

1. **Atomic Operations**: Use proper locking for status check and start
2. **Health Checks**: Make startup delays configurable
3. **Error Handling**: Properly categorize and handle different error types
4. **Monitoring**: Add metrics for container startup times and failures

### Example Safer Implementation

```go
// Validate container name
func isValidContainerName(name string) bool {
    // Only allow alphanumeric, dash, and underscore
    matched, _ := regexp.MatchString("^[a-zA-Z0-9_-]+$", name)
    return matched && len(name) < 64
}

// Use Docker SDK instead of exec
import "github.com/docker/docker/client"

func (od *OnDemandDocker) startContainerSafe() error {
    if !isValidContainerName(od.actualContainerName) {
        return fmt.Errorf("invalid container name")
    }
    
    cli, err := client.NewClientWithOpts(client.FromEnv)
    if err != nil {
        return err
    }
    defer cli.Close()
    
    return cli.ContainerStart(context.Background(), od.actualContainerName, types.ContainerStartOptions{})
}
```

## Conclusion

While the on-demand Docker functionality provides a convenient development experience, it has several security vulnerabilities and correctness issues that should be addressed:

1. **Command injection risks** through unsanitized container names
2. **No authorization controls** on container management
3. **Race conditions** in status checking and container startup
4. **Poor error handling** that could mask serious issues

Given that this is explicitly a development-only environment, some security trade-offs may be acceptable, but the command injection vulnerabilities should be fixed as they could compromise the host system.
