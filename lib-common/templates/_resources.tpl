{{/*
ServiceMonitor template
Usage: include "common.serviceMonitor" .
*/}}
{{- define "common.serviceMonitor" -}}
{{- if .Values.monitoring.enabled -}}
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: {{ include "common.fullname" . }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
    {{- if .Values.monitoring.labels }}
    {{- toYaml .Values.monitoring.labels | nindent 4 }}
    {{- end }}
spec:
  selector:
    matchLabels:
      {{- include "common.selectorLabels" . | nindent 6 }}
  endpoints:
    - port: {{ .Values.monitoring.portName | default "metrics" }}
      {{- if .Values.monitoring.interval }}
      interval: {{ .Values.monitoring.interval }}
      {{- end }}
      {{- if .Values.monitoring.scrapeTimeout }}
      scrapeTimeout: {{ .Values.monitoring.scrapeTimeout }}
      {{- end }}
      {{- if .Values.monitoring.path }}
      path: {{ .Values.monitoring.path }}
      {{- end }}
{{- end }}
{{- end }}

{{/*
PodMonitor template
Usage: include "common.podMonitor" .
*/}}
{{- define "common.podMonitor" -}}
{{- if .Values.monitoring.podMonitor.enabled -}}
apiVersion: monitoring.coreos.com/v1
kind: PodMonitor
metadata:
  name: {{ include "common.fullname" . }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
    {{- if .Values.monitoring.labels }}
    {{- toYaml .Values.monitoring.labels | nindent 4 }}
    {{- end }}
spec:
  selector:
    matchLabels:
      {{- include "common.selectorLabels" . | nindent 6 }}
  podMetricsEndpoints:
    - port: {{ .Values.monitoring.portName | default "metrics" }}
      {{- if .Values.monitoring.interval }}
      interval: {{ .Values.monitoring.interval }}
      {{- end }}
      {{- if .Values.monitoring.scrapeTimeout }}
      scrapeTimeout: {{ .Values.monitoring.scrapeTimeout }}
      {{- end }}
      {{- if .Values.monitoring.path }}
      path: {{ .Values.monitoring.path }}
      {{- end }}
{{- end }}
{{- end }}

{{/*
Default deny NetworkPolicy template
Usage: include "common.networkPolicy" .
*/}}
{{- define "common.networkPolicy" -}}
{{- if .Values.networkPolicy.enabled -}}
apiVersion: {{ include "common.capabilities.networkPolicy.apiVersion" . }}
kind: NetworkPolicy
metadata:
  name: {{ include "common.fullname" . }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
spec:
  podSelector:
    matchLabels:
      {{- include "common.selectorLabels" . | nindent 6 }}
  policyTypes:
    - Ingress
    - Egress
  {{- if .Values.networkPolicy.ingress }}
  ingress:
    {{- toYaml .Values.networkPolicy.ingress | nindent 4 }}
  {{- end }}
  egress:
    {{- if .Values.networkPolicy.egress }}
    {{- toYaml .Values.networkPolicy.egress | nindent 4 }}
    {{- else }}
    # Default: Allow DNS and NTP
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: kube-system
      ports:
        - protocol: UDP
          port: 53
    {{- if .Values.networkPolicy.allowNTP }}
    - to:
        - podSelector: {}
      ports:
        - protocol: UDP
          port: 123
    {{- end }}
    {{- end }}
{{- end }}
{{- end }}

{{/*
PodDisruptionBudget template
Usage: include "common.pdb" .
*/}}
{{- define "common.pdb" -}}
{{- if .Values.podDisruptionBudget.enabled -}}
apiVersion: {{ include "common.capabilities.pdb.apiVersion" . }}
kind: PodDisruptionBudget
metadata:
  name: {{ include "common.fullname" . }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
spec:
  selector:
    matchLabels:
      {{- include "common.selectorLabels" . | nindent 6 }}
  {{- if .Values.podDisruptionBudget.minAvailable }}
  minAvailable: {{ .Values.podDisruptionBudget.minAvailable }}
  {{- end }}
  {{- if .Values.podDisruptionBudget.maxUnavailable }}
  maxUnavailable: {{ .Values.podDisruptionBudget.maxUnavailable }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
HorizontalPodAutoscaler template
Usage: include "common.hpa" .
*/}}
{{- define "common.hpa" -}}
{{- if .Values.autoscaling.enabled -}}
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {{ include "common.fullname" . }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ include "common.fullname" . }}
  minReplicas: {{ .Values.autoscaling.minReplicas }}
  maxReplicas: {{ .Values.autoscaling.maxReplicas }}
  metrics:
    {{- if .Values.autoscaling.targetCPUUtilizationPercentage }}
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: {{ .Values.autoscaling.targetCPUUtilizationPercentage }}
    {{- end }}
    {{- if .Values.autoscaling.targetMemoryUtilizationPercentage }}
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: {{ .Values.autoscaling.targetMemoryUtilizationPercentage }}
    {{- end }}
{{- end }}
{{- end }}
