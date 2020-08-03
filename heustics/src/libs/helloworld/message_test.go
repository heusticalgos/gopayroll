package helloworld

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestHelloWorld(t *testing.T) {
	msg := CreateMsg("Tester")
	assert.Equal(t, "Howdy Doo Tester!", msg)
}
