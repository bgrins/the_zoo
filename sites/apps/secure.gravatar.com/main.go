package main

import (
	"crypto/md5"
	"encoding/hex"
	"image"
	"image/color"
	"image/png"
	"net/http"
	"strconv"
	"strings"
)

func generateIdenticon(hash string, size int) *image.RGBA {
	img := image.NewRGBA(image.Rect(0, 0, size, size))

	hashBytes, _ := hex.DecodeString(hash)
	if len(hashBytes) < 16 {
		hashBytes = md5.New().Sum([]byte(hash))
	}

	bgColor := color.RGBA{240, 240, 240, 255}
	fgColor := color.RGBA{hashBytes[0], hashBytes[1], hashBytes[2], 255}

	for y := 0; y < size; y++ {
		for x := 0; x < size; x++ {
			img.Set(x, y, bgColor)
		}
	}

	blockSize := size / 5
	for i := 0; i < 15; i++ {
		if hashBytes[i]%2 == 0 {
			row := i / 3
			col := i % 3

			for y := 0; y < blockSize; y++ {
				for x := 0; x < blockSize; x++ {
					img.Set(col*blockSize+x, row*blockSize+y, fgColor)
					img.Set((4-col)*blockSize+x, row*blockSize+y, fgColor)
				}
			}
		}
	}

	return img
}

func avatarHandler(w http.ResponseWriter, r *http.Request) {
	path := strings.TrimPrefix(r.URL.Path, "/avatar/")
	hash := strings.Split(path, "?")[0]

	if hash == "" {
		hash = "default"
	}

	sizeParam := r.URL.Query().Get("s")
	size := 80
	if sizeParam != "" {
		if s, err := strconv.Atoi(sizeParam); err == nil && s > 0 && s <= 512 {
			size = s
		}
	}

	img := generateIdenticon(hash, size)

	w.Header().Set("Content-Type", "image/png")
	w.Header().Set("Cache-Control", "public, max-age=86400")
	png.Encode(w, img)
}

func rootHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	w.Write([]byte("Gravatar avatar service"))
}

func main() {
	http.HandleFunc("/avatar/", avatarHandler)
	http.HandleFunc("/", rootHandler)
	http.ListenAndServe(":8080", nil)
}
