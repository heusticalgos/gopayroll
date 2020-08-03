package main

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestHelloWorld(t *testing.T) {
	msg := createMsg("Tester")
	assert.Equal(t, "Howdy Doo Tester!", msg)
}
