from flask import Flask, jsonify, request, render_template_string
import uuid
import os
import socket
from datetime import datetime

app = Flask(__name__)

HOME_TEMPLATE = """
<!DOCTYPE html>
<html>
<head>
    <title>Utils - utils.zoo</title>
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
        .utils-list {
            list-style: none;
            padding: 0;
        }
        .utils-list li {
            margin: 15px 0;
        }
        .utils-list a {
            display: inline-block;
            padding: 12px 20px;
            background: #007bff;
            color: white;
            text-decoration: none;
            border-radius: 5px;
            transition: background 0.2s;
        }
        .utils-list a:hover {
            background: #0056b3;
        }
        .utils-list .description {
            display: inline-block;
            margin-left: 15px;
            color: #666;
            font-size: 14px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Zoo Utilities</h1>
        <p class="description">A collection of useful utilities for the Zoo environment</p>
        
        <ul class="utils-list">
            <li>
                <a href="/uuid">UUID Generator</a>
                <span class="description">Generate a unique UUID</span>
            </li>
            <li>
                <a href="/whoami">Who Am I</a>
                <span class="description">View your IP address and user agent details</span>
            </li>
        </ul>
    </div>
</body>
</html>
"""

UUID_TEMPLATE = """
<!DOCTYPE html>
<html>
<head>
    <title>UUID Generator - utils.zoo</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            background: white;
            padding: 40px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            text-align: center;
        }
        h1 {
            color: #333;
            margin-bottom: 30px;
        }
        .uuid-display {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 8px;
            font-family: monospace;
            font-size: 20px;
            color: #007bff;
            word-break: break-all;
            margin-bottom: 30px;
            border: 2px solid #e9ecef;
        }
        .reload-btn {
            display: inline-block;
            padding: 12px 30px;
            background: #28a745;
            color: white;
            text-decoration: none;
            border-radius: 5px;
            transition: background 0.2s;
            margin: 0 10px;
        }
        .reload-btn:hover {
            background: #218838;
        }
        .home-link {
            display: inline-block;
            padding: 12px 30px;
            background: #6c757d;
            color: white;
            text-decoration: none;
            border-radius: 5px;
            transition: background 0.2s;
            margin: 0 10px;
        }
        .home-link:hover {
            background: #5a6268;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>UUID Generator</h1>
        <div class="uuid-display">{{ uuid_value }}</div>
        <a href="/uuid" class="reload-btn">Generate New UUID</a>
        <a href="/" class="home-link">Back to Home</a>
    </div>
</body>
</html>
"""

WHOAMI_TEMPLATE = """
<!DOCTYPE html>
<html>
<head>
    <title>Who Am I - utils.zoo</title>
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
            padding: 40px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 {
            color: #333;
            margin-bottom: 30px;
        }
        .info-table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 30px;
        }
        .info-table th {
            text-align: left;
            padding: 12px;
            background-color: #f8f9fa;
            border-bottom: 2px solid #dee2e6;
            color: #495057;
            font-weight: 600;
        }
        .info-table td {
            padding: 12px;
            border-bottom: 1px solid #dee2e6;
            font-family: monospace;
            color: #333;
        }
        .home-link {
            display: inline-block;
            padding: 12px 30px;
            background: #6c757d;
            color: white;
            text-decoration: none;
            border-radius: 5px;
            transition: background 0.2s;
        }
        .home-link:hover {
            background: #5a6268;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Who Am I</h1>
        <table class="info-table">
            <tr>
                <th>Your IP Address</th>
                <td>{{ client_ip }}</td>
            </tr>
            <tr>
                <th>User Agent</th>
                <td>{{ user_agent }}</td>
            </tr>
            <tr>
                <th>Request Method</th>
                <td>{{ method }}</td>
            </tr>
            <tr>
                <th>Protocol</th>
                <td>{{ protocol }}</td>
            </tr>
            <tr>
                <th>Host</th>
                <td>{{ host }}</td>
            </tr>
            <tr>
                <th>Accept Languages</th>
                <td>{{ accept_languages }}</td>
            </tr>
            <tr>
                <th>Accept Encoding</th>
                <td>{{ accept_encoding }}</td>
            </tr>
            <tr>
                <th>Container Hostname</th>
                <td>{{ container_hostname }}</td>
            </tr>
            <tr>
                <th>Container IP</th>
                <td>{{ container_ip }}</td>
            </tr>
        </table>
        <a href="/" class="home-link">Back to Home</a>
    </div>
</body>
</html>
"""


@app.route("/")
def home():
    return render_template_string(HOME_TEMPLATE)


@app.route("/uuid")
def generate_uuid():
    uuid_value = str(uuid.uuid4())
    return render_template_string(UUID_TEMPLATE, uuid_value=uuid_value)


@app.route("/whoami")
def whoami():
    # Get client IP - handle both direct and proxied requests
    # X-Forwarded-For can contain multiple IPs: client, proxy1, proxy2, ...
    # We want the first one (original client)
    client_ip = request.headers.get("X-Forwarded-For", request.remote_addr)
    if client_ip and "," in client_ip:
        # Get the first IP in the chain (the original client)
        client_ip = client_ip.split(",")[0].strip()

    # Also check X-Real-IP header which some proxies use
    if not client_ip or client_ip.startswith("172.") or client_ip.startswith("10."):
        real_ip = request.headers.get("X-Real-IP")
        if real_ip:
            client_ip = real_ip

    # Get container's own IP
    try:
        container_ip = socket.gethostbyname(socket.gethostname())
    except:
        container_ip = "Unknown"

    info = {
        "client_ip": client_ip,
        "user_agent": request.headers.get("User-Agent", "Unknown"),
        "method": request.method,
        "protocol": request.environ.get("SERVER_PROTOCOL", "Unknown"),
        "host": request.headers.get("Host", "Unknown"),
        "accept_languages": request.headers.get("Accept-Language", "None"),
        "accept_encoding": request.headers.get("Accept-Encoding", "None"),
        "container_hostname": os.environ.get("HOSTNAME", socket.gethostname()),
        "container_ip": container_ip,
    }

    return render_template_string(WHOAMI_TEMPLATE, **info)


@app.route("/health")
def health():
    return jsonify({"status": "healthy", "service": "utils-zoo"})


# Make it easy to add new utilities
@app.route("/api/uuid")
def api_uuid():
    return jsonify({"uuid": str(uuid.uuid4())})


@app.route("/api/whoami")
def api_whoami():
    # Get client IP - handle both direct and proxied requests
    # X-Forwarded-For can contain multiple IPs: client, proxy1, proxy2, ...
    # We want the first one (original client)
    client_ip = request.headers.get("X-Forwarded-For", request.remote_addr)
    if client_ip and "," in client_ip:
        # Get the first IP in the chain (the original client)
        client_ip = client_ip.split(",")[0].strip()

    # Also check X-Real-IP header which some proxies use
    if not client_ip or client_ip.startswith("172.") or client_ip.startswith("10."):
        real_ip = request.headers.get("X-Real-IP")
        if real_ip:
            client_ip = real_ip

    return jsonify(
        {
            "ip": client_ip,
            "user_agent": request.headers.get("User-Agent", "Unknown"),
            "method": request.method,
            "host": request.headers.get("Host", "Unknown"),
            "headers": dict(request.headers),
        }
    )


@app.route("/api/headers")
def api_headers():
    # Return all headers received by the application
    return jsonify(
        {
            "headers": dict(request.headers),
            "remote_addr": request.remote_addr,
            "x_forwarded_for": request.headers.get("X-Forwarded-For"),
            "x_real_ip": request.headers.get("X-Real-IP"),
        }
    )


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 3000))
    app.run(host="0.0.0.0", port=port, debug=True)
