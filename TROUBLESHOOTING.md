# 🛠️ Registro de Problemas y Soluciones (DevOps Troubleshooting)

Este documento detalla los desafíos técnicos, errores de configuración y bloqueos de infraestructura resueltos durante la construcción del proyecto.

## 1. Gestión de Repositorios y Git
*   **Problema:** `remote: error: File terraform/.terraform/... is 674.20 MB; this exceeds GitHub's file size limit of 100.00 MB`.
*   **Causa:** Se añadió la carpeta oculta de Terraform al control de versiones.
*   **Solución:** Se usó `git filter-repo --path terraform/.terraform/ --invert-paths --force` para purgar el historial. Posteriormente, se reconfiguró el remoto `origin` que `filter-repo` elimina por seguridad.

## 2. Infraestructura como Código (Terraform y AWS)
*   **Problema:** `InvalidKeyPair.NotFound: The key pair 'Prueba Terraform' does not exist`.
*   **Causa:** Los Key Pairs son específicos de cada región de AWS. El par estaba en otra región o el nombre tenía espacios.
*   **Solución:** Se configuró la región correcta y se generó el par de claves vía CLI (`aws ec2 create-key-pair`) con un nombre sin espacios (`prueba-terraform`).

*   **Problema:** Colapso de la instancia (pérdida de conexión) por falta de memoria (`Slow SQL`, `OOM`).
*   **Causa:** La instancia `t3.micro` (1 GB RAM) no soporta K3s + ArgoCD + Prometheus.
*   **Solución:** Se escaló la instancia a `c7i-flex.large` (4 GB RAM) modificando el `variables.tf` de Terraform.

*   **Problema:** `disk I/O error: no space left on device` en K3s.
*   **Causa:** El disco raíz por defecto de la instancia era de 2 GB.
*   **Solución:** Se modificó `main.tf` para añadir un bloque `root_block_device` de 20 GB tipo `gp3`. Se requirió `terraform destroy` + `apply` para aplicar el cambio.

## 3. Redes, Accesos y Kubeconfig
*   **Problema:** `dial tcp ***:22: i/o timeout` en GitHub Actions.
*   **Causa:** El Security Group solo permitía SSH desde la IP del desarrollador. GitHub usa IPs dinámicas.
*   **Solución:** Se abrió temporalmente el puerto 22 a `0.0.0.0/0` en el Security Group de AWS.

*   **Problema:** `The connection to the server 127.0.0.1:6443 was refused`.
*   **Causa:** El pipeline de GitHub Actions no cargaba las variables de entorno del `.bashrc` (donde estaba el `KUBECONFIG`), por lo que `kubectl` buscaba el clúster en localhost.
*   **Solución:** Se añadió `export KUBECONFIG=/home/ec2-user/.kube/config` explícitamente al inicio del script en `deploy.yml`.

## 4. Contenedores y Kubernetes
*   **Problema:** `CreateContainerConfigError` en los Pods de Task-API.
*   **Causa:** Los Pods intentaban leer variables de un `Secret` que no existía o no coincidía con el namespace.
*   **Solución:** Se estandarizó la creación del secreto usando `kubectl create secret` con `-n default`.

*   **Problema:** `Run Command Timeout` en GitHub Actions durante `kubectl rollout status`.
*   **Causa:** El comando esperaba a que muriera el Pod viejo, pero a veces K8s tarda más de 10 minutos en liberar réplicas huérfanas.
*   **Solución:** Se eliminó el `rollout status` y se añadió `kubectl delete pod -l app=task-api --ignore-not-found=true` antes del `apply` para forzar la limpieza.

## 5. GitOps y Seguridad (ArgoCD y Sealed Secrets)
*   **Problema:** `Resource "postgres-secret" already exists and is not managed by SealedSecret`.
*   **Causa:** Al intentar aplicar un `SealedSecret` que ya existía o cuyo secreto subyacente fue creado manualmente, el controlador de Sealed Secrets se niega a sobrescribirlo por seguridad.
*   **Solución:** Se añadió al pipeline un paso para borrar el `sealedsecret` antes de aplicarlo: `kubectl delete sealedsecret postgres-secret --ignore-not-found=true`. Esto obliga al controlador a descifrarlo de cero.

*   **Problema:** Error al cifrar secretos con `kubeseal` (namespace no encontrado).
*   **Causa:** Cifrado offline sin especificar el namespace en el manifiesto base.
*   **Solución:** Se añadió `-n default` al comando `kubectl create secret ... --dry-run=client` para que el YAML incluyera el namespace antes del cifrado.

*   **Problema:** `404 Not Found` al intentar acceder a ArgoCD por la IP pública.
*   **Causa:** La API (Task-API) tenía un Ingress en la ruta `/`, por lo que Traefik enviaba todas las peticiones a la API.
*   **Solución:** Se configuró ArgoCD para vivir en el subdirectorio `/argocd` (`server.rootpath`) y se modificó su Ingress.

---
**Conclusión:** 
*"En DevOps, el 80% del tiempo se dedica a entender por qué la red no enruta, por qué falla un secreto o por qué Linux ha matado un proceso. La resiliencia y el diagnóstico metódico son las herramientas más valiosas."*
