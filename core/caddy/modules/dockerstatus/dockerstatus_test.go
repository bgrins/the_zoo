package dockerstatus

import (
	"bytes"
	"encoding/binary"
	"strings"
	"testing"

	"github.com/thezoo/dockerapi"
)

// The expected strings are what `docker ps` printed for zoo containers before
// the module switched from the CLI to the API.
func TestDisplayPorts(t *testing.T) {
	tests := []struct {
		name  string
		ports []dockerapi.Port
		want  string
	}{
		{"none", nil, ""},
		{"protocols", []dockerapi.Port{{PrivatePort: 53, Type: "udp"}, {PrivatePort: 53, Type: "tcp"}}, "53/tcp, 53/udp"},
		{"ranges", []dockerapi.Port{
			{PrivatePort: 8074, Type: "tcp"}, {PrivatePort: 8065, Type: "tcp"},
			{PrivatePort: 8075, Type: "tcp"}, {PrivatePort: 8067, Type: "tcp"},
		}, "8065/tcp, 8067/tcp, 8074-8075/tcp"},
		{"published", []dockerapi.Port{
			{IP: "::", PrivatePort: 3128, PublicPort: 3128, Type: "tcp"},
			{IP: "0.0.0.0", PrivatePort: 3128, PublicPort: 3128, Type: "tcp"},
		}, "0.0.0.0:3128->3128/tcp, :::3128->3128/tcp"},
		{"remapped", []dockerapi.Port{
			{IP: "0.0.0.0", PrivatePort: 80, PublicPort: 8080, Type: "tcp"},
			{PrivatePort: 443, Type: "tcp"},
		}, "443/tcp, 0.0.0.0:8080->80/tcp"},
	}
	for _, tt := range tests {
		if got := displayPorts(tt.ports); got != tt.want {
			t.Errorf("%s: got %q, want %q", tt.name, got, tt.want)
		}
	}
}

func TestDisplayImage(t *testing.T) {
	id := "sha256:2cf7bcf4159b4e1b4d3c0d3f3ab5d1a0e9b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5"
	tests := []struct{ image, want string }{
		{id, "2cf7bcf4159b"},
		{"redis:7.4.7-alpine", "redis:7.4.7-alpine"},
		{"ghcr.io/bgrins/zoo-sites:sha-bbd91fc", "ghcr.io/bgrins/zoo-sites:sha-bbd91fc"},
		{"postgres:16@sha256:4ec37d2a07a0067f176fdcc9d4bb633a5724d2cc4f892c7a2046d054bb6939e5", "postgres:16"},
		{"docker.io/library/nginx:1.27", "nginx:1.27"},
		{"", "<no image>"},
	}
	for _, tt := range tests {
		if got := displayImage(tt.image, id); got != tt.want {
			t.Errorf("displayImage(%q) = %q, want %q", tt.image, got, tt.want)
		}
	}
}

func TestFormatStats(t *testing.T) {
	var s statsResponse
	s.CPUStats.CPUUsage.TotalUsage = 2e9
	s.PreCPUStats.CPUUsage.TotalUsage = 1e9
	s.CPUStats.SystemUsage = 20e9
	s.PreCPUStats.SystemUsage = 10e9
	s.CPUStats.OnlineCPUs = 4
	s.MemoryStats.Usage = 100 << 20
	s.MemoryStats.Limit = 1 << 30
	s.MemoryStats.Stats = map[string]uint64{"inactive_file": 50 << 20}
	s.BlkioStats.IoServiceBytesRecursive = []struct {
		Op    string `json:"op"`
		Value uint64 `json:"value"`
	}{{"read", 4100}, {"write", 1234567}}
	s.Networks = map[string]struct {
		RxBytes uint64 `json:"rx_bytes"`
		TxBytes uint64 `json:"tx_bytes"`
	}{"eth0": {1500, 999}, "eth1": {500, 0}}
	s.PidsStats.Current = 11

	want := ContainerStats{
		CPUPerc:  "40.00%",
		MemPerc:  "4.88%",
		MemUsage: "50MiB / 1GiB",
		NetIO:    "2kB / 999B",
		BlockIO:  "4.1kB / 1.23MB",
		PIDs:     "11",
	}
	if got := *formatStats(&s); got != want {
		t.Errorf("got %+v, want %+v", got, want)
	}
}

func TestDecimalSize(t *testing.T) {
	for size, want := range map[float64]string{
		999:     "999B",
		999499:  "999kB",
		999600:  "1MB",
		1234567: "1.23MB",
	} {
		if got := decimalSize(size); got != want {
			t.Errorf("decimalSize(%v) = %q, want %q", size, got, want)
		}
	}
}

func frame(stream byte, payload string) []byte {
	header := make([]byte, 8)
	header[0] = stream
	binary.BigEndian.PutUint32(header[4:], uint32(len(payload)))
	return append(header, payload...)
}

func TestDemuxLogs(t *testing.T) {
	var stream []byte
	stream = append(stream, frame(1, "listening on :80\n")...)
	stream = append(stream, frame(2, "warning: no config\n")...)
	stream = append(stream, frame(1, "ready\n")...)

	var out strings.Builder
	if err := demuxLogs(&out, bytes.NewReader(stream)); err != nil {
		t.Fatal(err)
	}
	if want := "listening on :80\nwarning: no config\nready\n"; out.String() != want {
		t.Errorf("got %q, want %q", out.String(), want)
	}

	if err := demuxLogs(&out, bytes.NewReader(stream[:len(stream)-2])); err == nil {
		t.Error("truncated stream was not reported")
	}
}
