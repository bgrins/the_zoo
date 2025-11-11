package main

import (
	"encoding/json"
	"net/http"
	"os"
	"strings"
)

func getClientIP(r *http.Request) string {
	// Get X-Forwarded-For header (contains chain of IPs)
	forwardedFor := r.Header.Get("X-Forwarded-For")
	if forwardedFor != "" {
		// Get the first IP in the chain (original client)
		ips := strings.Split(forwardedFor, ",")
		if len(ips) > 0 {
			return strings.TrimSpace(ips[0])
		}
	}

	// Fallback to X-Real-IP
	realIP := r.Header.Get("X-Real-IP")
	if realIP != "" {
		return realIP
	}

	// Fallback to RemoteAddr
	return r.RemoteAddr
}

func apiWhoamiHandler(w http.ResponseWriter, r *http.Request) {
	// Convert headers to a simple map
	headers := make(map[string]string)
	for name, values := range r.Header {
		headers[name] = strings.Join(values, ", ")
	}

	response := map[string]interface{}{
		"ip":         getClientIP(r),
		"user_agent": r.UserAgent(),
		"method":     r.Method,
		"host":       r.Host,
		"headers":    headers,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func apiHeadersHandler(w http.ResponseWriter, r *http.Request) {
	// Convert headers to a simple map
	headers := make(map[string]string)
	for name, values := range r.Header {
		headers[name] = strings.Join(values, ", ")
	}

	response := map[string]interface{}{
		"headers":         headers,
		"remote_addr":     r.RemoteAddr,
		"x_forwarded_for": r.Header.Get("X-Forwarded-For"),
		"x_real_ip":       r.Header.Get("X-Real-IP"),
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	response := map[string]string{
		"status":  "healthy",
		"service": "misc.zoo",
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func rootHandler(w http.ResponseWriter, r *http.Request) {
	html := `<!DOCTYPE html>
<html>
<head>
    <title>Misc Zoo</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 {
            color: #333;
            margin-bottom: 10px;
        }
        .description {
            color: #666;
            margin-bottom: 30px;
        }
        .endpoints {
            list-style: none;
            padding: 0;
        }
        .endpoints li {
            margin: 15px 0;
            padding: 12px;
            background: #f8f9fa;
            border-radius: 5px;
            font-family: monospace;
        }
        .endpoints a {
            color: #007bff;
            text-decoration: none;
        }
        .endpoints a:hover {
            text-decoration: underline;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🔧 Misc Zoo</h1>
        <p class="description">Miscellaneous utilities and test endpoints for The Zoo</p>

        <h2>Available Endpoints:</h2>
        <ul class="endpoints">
            <li><a href="/api/whoami">GET /api/whoami</a> - Client IP and request information</li>
            <li><a href="/api/headers">GET /api/headers</a> - All request headers</li>
            <li><a href="/health">GET /health</a> - Health check</li>
        </ul>
    </div>
</body>
</html>`

	w.Header().Set("Content-Type", "text/html")
	w.WriteHeader(http.StatusOK)
	w.Write([]byte(html))
}

func main() {
	http.HandleFunc("/api/whoami", apiWhoamiHandler)
	http.HandleFunc("/api/headers", apiHeadersHandler)
	http.HandleFunc("/health", healthHandler)
	http.HandleFunc("/", rootHandler)

	port := os.Getenv("PORT")
	if port == "" {
		port = "3000"
	}

	http.ListenAndServe(":"+port, nil)
}
