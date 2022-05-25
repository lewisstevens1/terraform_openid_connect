package test

import (
	"encoding/json"
	"fmt"
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

type Provider struct {
	Enabled    bool                  `json:"enabled"`
	Workspace  string                `json:"workspace_name"`
	Permission []PermissionStatement `json:"permission_statements,omitempty"`
}

type PermissionStatement struct {
	Sid      string
	Effect   string
	Action   []string
	Resource string
}

func providerToJson(p Provider) string {
	resp, err := json.Marshal(p)

	if err != nil {
		fmt.Println("Error converting to JSON:", err)
		os.Exit(1)
	}

	return string(resp)
}

func getPermissionStatements(count int) []PermissionStatement {
	perms := []PermissionStatement{}

	for i := 0; i < count; i++ {
		perms = append(
			perms,
			PermissionStatement{
				Sid:    "Sid",
				Effect: "Deny",
				Action: []string{
					"kms:Encrypt",
				},
				Resource: "arn:aws:kms:*:*:key/*",
			},
		)
	}

	return perms
}

func TestOpenIdConnectApply(t *testing.T) {
	// Test that the policy can be created with random permission statements.

	terraformOptions := &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"github": providerToJson(
				Provider{
					Enabled:    true,
					Workspace:  "test",
					Permission: getPermissionStatements(1),
				},
			),
		},
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	c_cert_thumprints := terraform.Output(t, terraformOptions, "count_certificate_thumbprints")
	c_created_providers := terraform.Output(t, terraformOptions, "count_created_providers")
	c_expected_providers := terraform.Output(t, terraformOptions, "count_expected_providers")

	fmt.Println("Testing that the expected providers match the created providers.")
	assert.Equal(t, c_created_providers, c_expected_providers)

	fmt.Println("Testing that the provider thumprints match the amount of created providers.")
	assert.Equal(t, c_cert_thumprints, c_created_providers)
}

func TestOpenIdConnectNoPermissions(t *testing.T) {
	// Test that the policy can be created still with the policies default permissions due to not being passed any permission statements.

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"github": providerToJson(
				Provider{
					Enabled:   true,
					Workspace: "test",
				},
			),
		},
	})

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	c_cert_thumprints := terraform.Output(t, terraformOptions, "count_certificate_thumbprints")
	c_created_providers := terraform.Output(t, terraformOptions, "count_created_providers")
	c_expected_providers := terraform.Output(t, terraformOptions, "count_expected_providers")

	fmt.Println("Testing that the expected providers match the created providers.")
	assert.Equal(t, c_created_providers, c_expected_providers)

	fmt.Println("Testing that the provider thumprints match the amount of created providers.")
	assert.Equal(t, c_cert_thumprints, c_created_providers)
}
