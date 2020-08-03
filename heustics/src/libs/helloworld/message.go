package helloworld

import "fmt"

// CreateMsg returns a greeting message for the given @name.
func CreateMsg(name string) string {
	return fmt.Sprintf("Howdy Doo %s!", name)
}
