{{/*
Expand the name of the chart.
*/}}
{{- define "phpmyadmin.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "phpmyadmin.fullname" -}}
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
{{- define "phpmyadmin.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "phpmyadmin.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{ include "phpmyadmin.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
helm.sh/chart: {{ include "phpmyadmin.chart" . }}
{{- with .Values.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "phpmyadmin.selectorLabels" -}}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/name: {{ include "phpmyadmin.name" . }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "phpmyadmin.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "phpmyadmin.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create a default fully qualified app name for database dependency.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "phpmyadmin.databaseHost" -}}
{{- if .Values.db.host -}}
{{- .Values.db.host -}}
{{- else -}}
{{- printf "%s-mysql" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Get the database port
*/}}
{{- define "phpmyadmin.databasePort" -}}
{{- .Values.db.port | default 3306 -}}
{{- end -}}

{{/*
Return the proper phpMyAdmin image name
*/}}
{{- define "phpmyadmin.image" -}}
{{- $registry := .Values.image.registry -}}
{{- $repository := .Values.image.repository -}}
{{- $tag := .Values.image.tag | default .Chart.AppVersion -}}
{{- if $registry -}}
{{- printf "%s/%s:%s" $registry $repository $tag -}}
{{- else -}}
{{- printf "%s:%s" $repository $tag -}}
{{- end -}}
{{- end -}}

{{/*
Return the proper Docker Image Registry Secret Names
*/}}
{{- define "phpmyadmin.imagePullSecrets" -}}
{{- if .Values.image.pullSecrets }}
imagePullSecrets:
{{- range .Values.image.pullSecrets }}
  - name: {{ . }}
{{- end }}
{{- end -}}
{{- end -}}

{{/*
Return the proper phpMyAdmin image name
*/}}
{{- define "phpmyadmin.imageRegistry" -}}
{{- if .Values.global }}
{{- if .Values.global.imageRegistry }}
{{- .Values.global.imageRegistry -}}
{{- else -}}
{{- .Values.image.registry -}}
{{- end -}}
{{- else -}}
{{- .Values.image.registry -}}
{{- end -}}
{{- end -}}

{{/*
Return the proper phpMyAdmin image name
*/}}
{{- define "phpmyadmin.imageRepository" -}}
{{- .Values.image.repository -}}
{{- end -}}

{{/*
Return the proper phpMyAdmin image tag
*/}}
{{- define "phpmyadmin.imageTag" -}}
{{- .Values.image.tag | default .Chart.AppVersion -}}
{{- end -}}

{{/*
Return the proper image name (for the init container volume-permissions image)
*/}}
{{- define "phpmyadmin.volumePermissions.image" -}}
{{- include "common.images.image" ( dict "imageRoot" .Values.volumePermissions.image "global" .Values.global ) -}}
{{- end -}}

{{/*
Check if there are rolling tags in the images
*/}}
{{- define "phpmyadmin.checkRollingTags" -}}
{{- include "common.warnings.rollingTag" .Values.image -}}
{{- end -}}

{{/*
Compile all warnings into a single message, and call fail.
*/}}
{{- define "phpmyadmin.validateValues" -}}
{{- $messages := list -}}
{{- $messages := append $messages (include "phpmyadmin.validateValues.database" .) -}}
{{- $messages := without $messages "" -}}
{{- $message := join "\n" $messages -}}

{{- if $message -}}
{{-   printf "\nVALUES VALIDATION:\n%s" $message | fail -}}
{{- end -}}
{{- end -}}

{{/*
Validate values of phpMyAdmin - Database
*/}}
{{- define "phpmyadmin.validateValues.database" -}}
{{- if and (not .Values.db.host) (not .Values.db.allowArbitraryServer) -}}
phpmyadmin: database
    You must provide a database host (--set db.host="xxxx")
    or enable arbitrary server connections (--set db.allowArbitraryServer=true)
{{- end -}}
{{- end -}}

{{/*
Return true if a TLS secret object should be created
*/}}
{{- define "phpmyadmin.createTlsSecret" -}}
{{- if and .Values.ingress.enabled .Values.ingress.tls (not .Values.ingress.existingSecret) (eq .Values.ingress.tls true) }}
    {{- true -}}
{{- end -}}
{{- end -}}

{{/*
Return the TLS secret name to use
*/}}
{{- define "phpmyadmin.tlsSecretName" -}}
{{- $secretName := .Values.ingress.existingSecret -}}
{{- if and .Values.ingress.enabled .Values.ingress.tls -}}
    {{- $secretName = printf "%s-tls" .Values.ingress.hostname -}}
{{- end -}}
{{- printf "%s" $secretName -}}
{{- end -}}

{{/*
Renders a value that contains template.
Usage:
{{ include "phpmyadmin.tplValue" ( dict "value" .Values.path.to.the.Value "context" $) }}
*/}}
{{- define "phpmyadmin.tplValue" -}}
    {{- if typeIs "string" .value }}
        {{- tpl .value .context }}
    {{- else }}
        {{- tpl (.value | toYaml) .context }}
    {{- end }}
{{- end -}}

{{/*
Common annotations
*/}}
{{- define "phpmyadmin.annotations" -}}
{{- with .Values.commonAnnotations }}
{{ toYaml . }}
{{- end }}
{{- end }}
