{{/*
Expand the name of the chart.
*/}}
{{- define "common.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "common.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "common.chart" -}}
{{- printf "%s-%s" .Chart.Name (.Chart.Version | replace "+" "_") | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "common.labels" -}}
helm.sh/chart: {{ include "common.chart" . }}
{{ include "common.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- if .Values.commonLabels }}
{{ toYaml .Values.commonLabels }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "common.selectorLabels" -}}
app.kubernetes.io/name: {{ include "common.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "common.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "common.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Return the appropriate apiVersion for NetworkPolicy
*/}}
{{- define "common.capabilities.networkPolicy.apiVersion" -}}
{{- print "networking.k8s.io/v1" -}}
{{- end }}

{{/*
Return the appropriate apiVersion for Ingress
*/}}
{{- define "common.capabilities.ingress.apiVersion" -}}
{{- print "networking.k8s.io/v1" -}}
{{- end }}

{{/*
Return the appropriate apiVersion for PodDisruptionBudget
*/}}
{{- define "common.capabilities.pdb.apiVersion" -}}
{{- if semverCompare ">=1.21-0" .Capabilities.KubeVersion.Version -}}
{{- print "policy/v1" -}}
{{- else -}}
{{- print "policy/v1beta1" -}}
{{- end -}}
{{- end }}

{{/*
Common pod security context with hardened defaults
*/}}
{{- define "common.podSecurityContext" -}}
runAsNonRoot: true
{{- if .Values.podSecurityContext }}
{{- toYaml .Values.podSecurityContext | nindent 0 }}
{{- end }}
{{- end }}

{{/*
Common container security context with hardened defaults
*/}}
{{- define "common.securityContext" -}}
runAsNonRoot: true
readOnlyRootFilesystem: true
allowPrivilegeEscalation: false
capabilities:
  drop:
    - ALL
{{- if .Values.securityContext }}
{{- toYaml .Values.securityContext | nindent 0 }}
{{- end }}
{{- end }}

{{/*
Common liveness probe
*/}}
{{- define "common.livenessProbe" -}}
{{- if .Values.livenessProbe }}
{{- toYaml .Values.livenessProbe }}
{{- end }}
{{- end }}

{{/*
Common readiness probe
*/}}
{{- define "common.readinessProbe" -}}
{{- if .Values.readinessProbe }}
{{- toYaml .Values.readinessProbe }}
{{- end }}
{{- end }}

{{/*
Common startup probe
*/}}
{{- define "common.startupProbe" -}}
{{- if .Values.startupProbe }}
{{- toYaml .Values.startupProbe }}
{{- end }}
{{- end }}

{{/*
Common image pull secrets
*/}}
{{- define "common.imagePullSecrets" -}}
{{- if .Values.imagePullSecrets }}
imagePullSecrets:
{{- range .Values.imagePullSecrets }}
  - name: {{ . }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Common priority class name
*/}}
{{- define "common.priorityClassName" -}}
{{- if .Values.priorityClassName }}
priorityClassName: {{ .Values.priorityClassName }}
{{- end }}
{{- end }}

{{/*
Common node selector
*/}}
{{- define "common.nodeSelector" -}}
{{- if .Values.nodeSelector }}
nodeSelector:
{{- toYaml .Values.nodeSelector | nindent 2 }}
{{- end }}
{{- end }}

{{/*
Common affinity
*/}}
{{- define "common.affinity" -}}
{{- if .Values.affinity }}
affinity:
{{- toYaml .Values.affinity | nindent 2 }}
{{- end }}
{{- end }}

{{/*
Common tolerations
*/}}
{{- define "common.tolerations" -}}
{{- if .Values.tolerations }}
tolerations:
{{- toYaml .Values.tolerations | nindent 0 }}
{{- end }}
{{- end }}

{{/*
Common topology spread constraints
*/}}
{{- define "common.topologySpreadConstraints" -}}
{{- if .Values.topologySpreadConstraints }}
topologySpreadConstraints:
{{- toYaml .Values.topologySpreadConstraints | nindent 0 }}
{{- end }}
{{- end }}
