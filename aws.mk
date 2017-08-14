MAKEFLAGS = -s

ifndef AWS_PROFILE
	AWS_PROFILE = aws-??
endif

ifndef STACK_NAME
	STACK_NAME = team_X-operations
endif
