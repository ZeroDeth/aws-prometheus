include ../aws.mk

.PHONY: create-stack update-stack

create-stack:
	aws --profile=$(AWS_PROFILE) cloudformation create-stack --stack-name $(STACK_NAME) --template-body file://cfn.yml --parameters file://cfn-parameters.json --capabilities CAPABILITY_IAM

update-stack:
	aws --profile=$(AWS_PROFILE) cloudformation update-stack --stack-name $(STACK_NAME) --template-body file://cfn.yml --parameters file://cfn-parameters.json --capabilities CAPABILITY_IAM
