import json
import pulumi
import pulumi_aws as aws

trust_policy = {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": { "Service": "sagemaker.amazonaws.com" },
            "Action": "sts:AssumeRole"
        }
    ]
}

sagemaker_role = aws.iam.Role(
    "sagemakerRole",
    assume_role_policy=json.dumps(trust_policy),
    description="Role assumed by SageMaker for inference/training"
)

# (Optional) attach managed SageMaker policy or your custom policy
aws.iam.RolePolicyAttachment(
    "sagemakerManagedAttach",
    role=sagemaker_role.name,
    policy_arn="arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
)

pulumi.export("role_arn", sagemaker_role.arn)

## MODEL

sagemaker_model = aws.sagemaker.Model(
    "sagemakermodel",
    execution_role_arn=sagemaker_role.arn,
    primary_container=aws.sagemaker.ModelPrimaryContainerArgs(
    image="763104351884.dkr.ecr.us-east-1.amazonaws.com/huggingface-pytorch-inference:2.1.0-transformers4.37.0-cpu-py310-ubuntu22.04-v1.4",
    environment={
        "HF_MODEL_ID": "Helsinki-NLP/opus-mt-en-es",
        #"HF_MODEL_ID": "openai/whisper-tiny",
        "HF_TASK": "translation",
        }
    )
)

## ENDPOINT CONFIG 
sagemaker_endpoint_configuration = aws.sagemaker.EndpointConfiguration(
    "sagemakerendpointconfiguration",
    production_variants=[aws.sagemaker.EndpointConfigurationProductionVariantArgs(
    instance_type="ml.g4dn.xlarge",
    model_name=sagemaker_model.name,
    variant_name="default",
    initial_instance_count=1, 
    )]
)

## ENDPOINT 

sagemaker_endpoint = aws.sagemaker.Endpoint(
    "sagemakerendpoint",
    name="triforge-whisper-endpoint",
    endpoint_config_name=sagemaker_endpoint_configuration.name

)


## EXPORT Endpoint 
pulumi.export( "endpoint", sagemaker_endpoint.name)

## AWS SECRET MANAGER
secret_resource = aws.secretsmanager.Secret("secretResource",
    description="SageMaker Endpoint url",
    name="triforge-endpoint-secret",
    recovery_window_in_days=0,
)


secret_version_resource = aws.secretsmanager.SecretVersion("secretVersionResource",
    secret_id=secret_resource.id,
    secret_string=sagemaker_endpoint.name,
    )


