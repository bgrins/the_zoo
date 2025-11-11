package main

import (
	"crypto/rand"
	"encoding/base64"
	"encoding/gob"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"strings"

	"github.com/gorilla/sessions"
)

var store = sessions.NewCookieStore([]byte("misc-zoo-session-key-change-in-production"))

func init() {
	// Register types for gob encoding
	gob.Register(map[string]string{})

	store.Options = &sessions.Options{
		Path:     "/",
		MaxAge:   3600,
		HttpOnly: true,
		Secure:   false, // Allow HTTP for development
		SameSite: http.SameSiteLaxMode,
	}
}

type OAuthConfig struct {
	ClientID     string
	ClientSecret string
	AuthURL      string
	TokenURL     string
	UserInfoURL  string
	RedirectURI  string
}

var oauthConfig = OAuthConfig{
	ClientID:     getEnv("OAUTH_CLIENT_ID", "zoo-misc-app"),
	ClientSecret: getEnv("OAUTH_CLIENT_SECRET", "zoo-misc-secret"),
	AuthURL:      getEnv("OAUTH_AUTH_ENDPOINT", "http://auth.zoo/oauth2/auth"),
	TokenURL:     getEnv("OAUTH_TOKEN_ENDPOINT", "http://auth.zoo/oauth2/token"),
	UserInfoURL:  getEnv("OAUTH_USERINFO_ENDPOINT", "http://auth.zoo/userinfo"),
	RedirectURI:  getEnv("OAUTH_REDIRECT_URI", "http://misc.zoo/oauth/callback"),
}

func getEnv(key, fallback string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return fallback
}

func generateState() string {
	b := make([]byte, 16)
	rand.Read(b)
	return base64.URLEncoding.EncodeToString(b)
}

func getClientIP(r *http.Request) string {
	forwardedFor := r.Header.Get("X-Forwarded-For")
	if forwardedFor != "" {
		ips := strings.Split(forwardedFor, ",")
		if len(ips) > 0 {
			return strings.TrimSpace(ips[0])
		}
	}
	if realIP := r.Header.Get("X-Real-IP"); realIP != "" {
		return realIP
	}
	return r.RemoteAddr
}

func apiWhoamiHandler(w http.ResponseWriter, r *http.Request) {
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

	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	json.NewEncoder(w).Encode(response)
}

func apiHeadersHandler(w http.ResponseWriter, r *http.Request) {
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

	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	json.NewEncoder(w).Encode(response)
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	response := map[string]string{
		"status":  "healthy",
		"service": "misc.zoo",
	}

	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	json.NewEncoder(w).Encode(response)
}

func oauthLoginHandler(w http.ResponseWriter, r *http.Request) {
	session, err := store.Get(r, "misc-session")
	if err != nil {
		fmt.Printf("Session get error: %v\n", err)
	}

	state := generateState()
	session.Values["oauth_state"] = state

	err = session.Save(r, w)
	if err != nil {
		fmt.Printf("Session save error: %v\n", err)
		http.Error(w, "Session error", http.StatusInternalServerError)
		return
	}

	authURL, _ := url.Parse(oauthConfig.AuthURL)
	q := authURL.Query()
	q.Set("client_id", oauthConfig.ClientID)
	q.Set("redirect_uri", oauthConfig.RedirectURI)
	q.Set("response_type", "code")
	q.Set("scope", "openid profile email")
	q.Set("state", state)
	authURL.RawQuery = q.Encode()

	fmt.Printf("Redirecting to: %s\n", authURL.String())
	http.Redirect(w, r, authURL.String(), http.StatusFound)
}

func oauthCallbackHandler(w http.ResponseWriter, r *http.Request) {
	session, err := store.Get(r, "misc-session")
	if err != nil {
		fmt.Printf("Callback session get error: %v\n", err)
	}

	// Verify state
	expectedState, _ := session.Values["oauth_state"].(string)
	receivedState := r.URL.Query().Get("state")

	fmt.Printf("Expected state: %s, Received state: %s\n", expectedState, receivedState)

	if receivedState != expectedState {
		fmt.Printf("State mismatch! Session values: %v\n", session.Values)
		http.Error(w, "Invalid state parameter", http.StatusBadRequest)
		return
	}

	code := r.URL.Query().Get("code")
	if code == "" {
		http.Error(w, "No code in callback", http.StatusBadRequest)
		return
	}

	// Exchange code for token
	data := url.Values{}
	data.Set("grant_type", "authorization_code")
	data.Set("code", code)
	data.Set("redirect_uri", oauthConfig.RedirectURI)

	req, _ := http.NewRequest("POST", oauthConfig.TokenURL, strings.NewReader(data.Encode()))
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	req.SetBasicAuth(oauthConfig.ClientID, oauthConfig.ClientSecret)

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		http.Error(w, "Token exchange failed", http.StatusInternalServerError)
		return
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		http.Error(w, fmt.Sprintf("Token exchange failed: %s", body), http.StatusInternalServerError)
		return
	}

	var tokens map[string]interface{}
	json.NewDecoder(resp.Body).Decode(&tokens)

	accessToken, _ := tokens["access_token"].(string)

	// Get user info
	userReq, _ := http.NewRequest("GET", oauthConfig.UserInfoURL, nil)
	userReq.Header.Set("Authorization", "Bearer "+accessToken)

	userResp, err := client.Do(userReq)
	if err != nil {
		fmt.Printf("UserInfo request error: %v\n", err)
	} else if userResp.StatusCode == http.StatusOK {
		var userInfo map[string]interface{}
		json.NewDecoder(userResp.Body).Decode(&userInfo)
		fmt.Printf("Got user info: %v\n", userInfo)

		// Convert to map[string]string for gob encoding
		userInfoStr := make(map[string]string)
		for k, v := range userInfo {
			userInfoStr[k] = fmt.Sprintf("%v", v)
		}

		session.Values["user"] = userInfoStr
		err = session.Save(r, w)
		if err != nil {
			fmt.Printf("Session save error after userinfo: %v\n", err)
		}
	} else {
		fmt.Printf("UserInfo request failed with status: %d\n", userResp.StatusCode)
		body, _ := io.ReadAll(userResp.Body)
		fmt.Printf("UserInfo response body: %s\n", body)
	}

	http.Redirect(w, r, "/", http.StatusFound)
}

func oauthLogoutHandler(w http.ResponseWriter, r *http.Request) {
	session, _ := store.Get(r, "misc-session")
	delete(session.Values, "user")
	session.Save(r, w)
	http.Redirect(w, r, "/", http.StatusFound)
}

func clearCookiesHandler(w http.ResponseWriter, r *http.Request) {
	// Clear the session cookie
	http.SetCookie(w, &http.Cookie{
		Name:   "misc-session",
		Value:  "",
		Path:   "/",
		MaxAge: -1,
	})
	http.Redirect(w, r, "/", http.StatusFound)
}

func rootHandler(w http.ResponseWriter, r *http.Request) {
	session, _ := store.Get(r, "misc-session")
	user, _ := session.Values["user"].(map[string]string)

	userSection := ""
	if user != nil {
		userName := "User"
		if name, ok := user["name"]; ok && name != "" {
			userName = name
		} else if sub, ok := user["sub"]; ok {
			userName = sub
		}

		userJSON, _ := json.MarshalIndent(user, "", "  ")
		userSection = fmt.Sprintf(`
        <div style="background: #e7f3ff; padding: 20px; border-radius: 5px; margin-bottom: 20px;">
            <h2>Welcome, %s!</h2>
            <pre style="background: #f5f5f5; padding: 10px; border-radius: 5px; overflow-x: auto;">%s</pre>
            <a href="/oauth/logout" style="background: #dc3545; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; display: inline-block;">Logout</a>
        </div>`, userName, string(userJSON))
	} else {
		userSection = `
        <div style="background: #f8f9fa; padding: 20px; border-radius: 5px; margin-bottom: 20px;">
            <p>Test OAuth2 authentication with auth.zoo</p>
            <a href="/oauth/login" style="background: #28a745; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; display: inline-block; margin-right: 10px;">Login with OAuth2</a>
            <a href="/clear-cookies" style="background: #6c757d; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; display: inline-block;">Clear Cookies</a>
        </div>`
	}

	html := fmt.Sprintf(`<!DOCTYPE html>
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

        %s

        <h2>API Endpoints:</h2>
        <ul class="endpoints">
            <li><a href="/api/whoami">GET /api/whoami</a> - Client IP and request information</li>
            <li><a href="/api/headers">GET /api/headers</a> - All request headers</li>
            <li><a href="/health">GET /health</a> - Health check</li>
        </ul>
    </div>
</body>
</html>`, userSection)

	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	w.WriteHeader(http.StatusOK)
	w.Write([]byte(html))
}

func main() {
	http.HandleFunc("/api/whoami", apiWhoamiHandler)
	http.HandleFunc("/api/headers", apiHeadersHandler)
	http.HandleFunc("/health", healthHandler)
	http.HandleFunc("/oauth/login", oauthLoginHandler)
	http.HandleFunc("/oauth/callback", oauthCallbackHandler)
	http.HandleFunc("/oauth/logout", oauthLogoutHandler)
	http.HandleFunc("/clear-cookies", clearCookiesHandler)
	http.HandleFunc("/", rootHandler)

	port := os.Getenv("PORT")
	if port == "" {
		port = "3000"
	}

	http.ListenAndServe(":"+port, nil)
}
