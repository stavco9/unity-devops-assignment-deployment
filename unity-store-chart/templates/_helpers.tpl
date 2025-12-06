{{- define "unity-store.name" -}}
{{- default .Chart.Name .Values.microservice.name | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "unity-store.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trimSuffix "-" }}
{{- end }}

{{/*
Create IAM Role Name
*/}}
{{- define "unity-store.iamRoleName" -}}
{{ include "unity-store.name" .}}-{{ .Release.Namespace }}-{{ .Values.irsa.awsRegion | default "us-east-1" }}
{{- end }}


{{/*
Common labels
*/}}
{{- define "unity-store.labels" -}}
helm.sh/chart: {{ include "unity-store.chart" . }}
{{ include "unity-store.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
microservice: {{ .Values.microservice.name }}
environment: {{ .Values.microservice.environment }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "unity-store.selectorLabels" -}}
app.kubernetes.io/name: {{ include "unity-store.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
microservice: {{ .Values.microservice.name }}
environment: {{ .Values.microservice.environment }}
{{- end }}

{{/*
Ingress object name
*/}}
{{- define "unity-store.ingress.name" -}}
{{- if .Values.autoscaling.http.enabled -}}
{{- printf "%s-%s-keda" .Release.Namespace (include "unity-store.name" .) -}}
{{- else }}
{{- include "unity-store.name" . -}}
{{- end }}
{{- end }}

{{/*
Ingress object namespace
*/}}
{{- define "unity-store.ingress.namespace" -}}
{{- if .Values.autoscaling.http.enabled }}
{{- printf "%s" .Values.autoscaling.http.kedaNamespace | default "keda" }}
{{- else }}
{{- printf "%s" .Release.Namespace }}
{{- end }}
{{- end }}

{{/*
Ingress annotations
*/}}
{{- define "unity-store.ingress.annotations" -}}

external-dns.alpha.kubernetes.io/hostname: {{ .Values.ingress.host }}

{{/*
Use Let's Encrypt ACME for any Ingress Controller which is no AWS ALB (Since in ALB we use the AWS ACM Certificate)
*/}}
{{- if .Values.ingress.protocol | eq "https" }}
cert-manager.io/cluster-issuer: letsencrypt-prod
kubernetes.io/tls-acme: 'true'
{{- end }}

{{/*
Annotation for NGINX Ingress Controller
*/}}
{{- if and (.Values.ingress.protocol | eq "https") (.Values.ingress.ingressClassName | eq "nginx") }}
nginx.ingress.kubernetes.io/force-ssl-redirect: 'true'
{{- end }}

{{/*
Whether the ALB listens on HTTP or HTTPS (In case of HTTPS it redirects HTTP traffic to HTTPS)
*/}}
{{- if .Values.ingress.protocol | eq "https" }}
alb.ingress.kubernetes.io/listen-ports: '[{"HTTP":80}, {"HTTPS":443}]'
alb.ingress.kubernetes.io/ssl-redirect: '443'
{{- else }}
alb.ingress.kubernetes.io/listen-ports: '[{"HTTP":80}]'
{{- end }}
{{- end }}

{{- define "unity-store.ingressClassName" -}}
{{- default "nginx" .Values.ingress.ingressClassName }}
{{- end }}