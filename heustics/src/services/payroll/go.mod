module services/payroll

go 1.14

require (
	github.com/stretchr/testify v1.6.1
	libs/helloworld v0.0.0
)

replace libs/helloworld v0.0.0 => ../../libs/helloworld
