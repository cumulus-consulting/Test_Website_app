{{- define "myapp.name" -}}
myapp
{{- end -}}

{{- define "myapp.fullname" -}}
{{ include "myapp.name" . }}-{{ .Release.Name }}
{{- end -}}
