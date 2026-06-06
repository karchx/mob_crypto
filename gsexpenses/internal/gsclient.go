package internal

import (
	"fmt"
	"log"
	"os"

	"golang.org/x/oauth2/google"
	"golang.org/x/oauth2/jwt"
)

// GetClient return jwt config oauth2
func GetClient() *jwt.Config {
	tokFile := "token.json"
	tok, err := tokenFromFile(tokFile)
	if err != nil {
		fmt.Printf("[gsclient]: error get token from file %v", err)
		return nil
	}
	return tok
}

func tokenFromFile(tokFile string) (*jwt.Config, error) {
	b, err := os.ReadFile(tokFile)
	if err != nil {
		log.Fatalf("Unable to read client secret file: %v", err)
		return nil, err
	}

	// scopes
	config, err := google.JWTConfigFromJSON(b, "https://www.googleapis.com/auth/spreadsheets.readonly")
	if err != nil {
		log.Fatalf("Unable to parse client secret file to config: %v", err)
	}
	return config, err
}
