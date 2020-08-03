package main

import (
	"fmt"

	"libs/helloworld"
)

func main() {
	msg := createMsg("Mr. Yogi")
	fmt.Println(msg)
}

func createMsg(name string) string {
	return helloworld.CreateMsg(name)
}
