#version 450

layout (location = 0) in vec3 inPos;
layout (location = 1) in vec3 inNormal;
layout (location = 2) in vec2 inUV;
layout (location = 3) in vec3 inColor;
layout (location = 4) in vec4 inJointIndices;
layout (location = 5) in vec4 inJointWeights;

layout (set = 0, binding = 0) uniform UBOScene
{
	mat4 projection;
	mat4 view;
	vec4 lightPos;
} uboScene;

layout(push_constant) uniform PushConsts {
	mat4 model;
} primitive;

layout(std430, set = 1, binding = 0) readonly buffer JointMatrices {
	mat4 jointMatrices[];
};

layout (location = 0) out vec3 outNormal;
layout (location = 1) out vec3 outColor;
layout (location = 2) out vec2 outUV;
layout (location = 3) out vec3 outViewVec;
layout (location = 4) out vec3 outLightVec;

void main()
{
	outNormal = inNormal;
	outColor = inColor;
	outUV = inUV;

	// Calculate skinned matrix from weights and joint indices of the current vertex
	mat4 skinMat =
		inJointWeights.x * jointMatrices[int(inJointIndices.x)] +
		inJointWeights.y * jointMatrices[int(inJointIndices.y)] +
		inJointWeights.z * jointMatrices[int(inJointIndices.z)] +
		inJointWeights.w * jointMatrices[int(inJointIndices.w)];

	gl_Position = uboScene.projection * uboScene.view * primitive.model * skinMat * vec4(inPos.xyz, 1.0);

	outNormal = normalize(transpose(inverse(mat3(uboScene.view * primitive.model * skinMat))) * inNormal);

	vec4 pos = uboScene.view * vec4(inPos, 1.0);
	vec3 lPos = mat3(uboScene.view) * uboScene.lightPos.xyz;
	outLightVec = lPos - pos.xyz;
	outViewVec = -pos.xyz;
}