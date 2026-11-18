Durante el desarrollo surgieron múltiples bloqueos técnicos. Aquí está el registro de cómo se diagnosticaron y resolvieron:
1. Docker Compose no reconocido (Fedora)

    Error: unknown command: docker compose / unknown flag: --build.

    Causa: El plugin de Compose V2 no estaba instalado en el sistema.

    Solución: Instalar el plugin con sudo dnf install docker-compose-plugin. Añadir el usuario al grupo docker para no usar sudo.

2. Archivos gigantes rechazados en Git

    Error: File terraform/.terraform/... is 674.20 MB; this exceeds GitHub's file size limit of 100.00 MB.

    Causa: Se añadió la carpeta local de Terraform (.terraform) al control de versiones.

    Solución: Crear un .gitignore, usar git rm -r --cached y purgar el historial con git filter-repo --path terraform/.terraform/ --invert-paths --force para reescribir los commits.

3. Error de Terraform: Key Pair no encontrado

    Error: InvalidKeyPair.NotFound: The key pair 'Prueba Terraform' does not exist.

    Causa: Confusión de región en AWS CLI (Global en lugar de eu-west-1) y un nombre con espacios.

    Solución: Configurar la región correcta (aws configure set region eu-west-1) y crear el par de claves vía CLI (aws ec2 create-key-pair).

4. Fallo de autenticación SSH en GitHub Actions

    Error: missing server host / ssh: unable to authenticate.

    Causa: Los secretos en GitHub estaban guardados en un "Environment" en lugar de "Repository secrets", y un error tipográfico en el usuario (ec2_user en vez de ec2-user).

    Solución: Mover los secretos al nivel de repositorio y corregir el nombre del usuario.

5. Timeout en el pipeline de despliegue

    Error: dial tcp ***:22: i/o timeout.

    Causa: El Security Group de AWS solo permitía SSH desde la IP local del desarrollador, bloqueando las IPs dinámicas de los servidores de GitHub Actions.

    Solución: Abrir temporalmente el puerto 22 a 0.0.0.0/0 en el Security Group.

6. Base de datos inaccesible (Connection Refused)

    Error: sqlalchemy.exc.OperationalError: connection to server at "localhost" port 5432 failed.

    Causa: El contenedor de la API buscaba la BD en su propio localhost en lugar de en el contenedor de Postgres.

    Solución: Crear una red en Docker (docker network create task-net) y usar el nombre del contenedor como host (@db:5432).

7. Contenedor en bucle (CrashLoopBackOff)

    Error: SyntaxError: invalid syntax en main.py.

    Causa: Al añadir Prometheus, se duplicó el código y la indentación de Python se rompió.

    Solución: Unificar el archivo main.py en una sola instancia de FastAPI e importar correctamente Instrumentator.

8. Colapso del sistema al instalar K3s

    Error: Pérdida de conexión SSH y Slow SQL en los logs.

    Causa: La instancia t3.micro (1 GB RAM) se quedó sin memoria al levantar K8s, provocando el bloqueo del sistema operativo (OOM).

    Solución: Reiniciar la instancia desde la consola de AWS para recuperar el acceso y configurar correctamente el archivo ~/.kube/config para que el usuario ec2-user pudiera usar kubectl.

9. Error de sintaxis en el Workflow de GitHub

    Error: Invalid workflow file: A sequence was not expected.

    Causa: Falta de indentación o pérdida de las claves raíz (jobs, steps) al pegar el código YAML.

    Solución: Reestructurar el deploy.yml respetando la jerarquía de YAML de GitHub Actions.

10. Migración a Ingress (Puerto 80)

    Error: La API solo era accesible por el puerto 30080 (NodePort).

    Solución: Crear un recurso Ingress en Kubernetes para que Traefik escuche en el puerto 80 y lo redirija internamente al servicio de la API en el puerto 8080.



------------------


1. Gestión de Repositorios y Git

    Problema: remote: error: File terraform/.terraform/... is 674.20 MB; this exceeds GitHub's file size limit of 100.00 MB.

    Causa: Se añadió la carpeta oculta de Terraform (.terraform) al control de versiones, la cual contiene los binarios del proveedor de AWS.

    Solución: Se añadió un .gitignore, pero como el archivo ya estaba en el historial, fue necesario purgar los commits usando git filter-repo --path terraform/.terraform/ --invert-paths --force. Posteriormente, hubo que reconfigurar el remoto origin que filter-repo elimina por seguridad.

    Problema: fatal: Las ramas se han divergido y hay que especificar cómo reconciliarlas.

    Causa: Se hicieron cambios locales en la rama main mientras que en GitHub se hizo un Merge de un Pull Request (creando un commit nuevo).

    Solución: Se usó git fetch origin y git reset --hard origin/main para forzar que la rama local fuera idéntica a la de GitHub, descartando los cambios locales conflictivos.

2. Infraestructura como Código (Terraform y AWS)

    Problema: InvalidKeyPair.NotFound: The key pair 'Prueba Terraform' does not exist.

    Causa: Los Key Pairs en AWS son específicos de cada región. El par de claves estaba en otra región o tenía un nombre con espacios.

    Solución: Se configuró la región correcta (aws configure set region eu-south-2) y se generó el par de claves vía CLI (aws ec2 create-key-pair) con un nombre sin espacios (prueba-terraform).

    Problema: Instancia EC2 colapsada (pérdida de conexión SSH y ping) tras instalar K3s. Logs mostrando Slow SQL y Out of memory.

    Causa: La instancia t3.micro (1 GB RAM) no tiene recursos suficientes para el sistema operativo, K3s, ArgoCD y Prometheus. El OOM Killer de Linux terminó matando procesos críticos.

    Solución: Se reinició la instancia desde la consola de AWS y se modificó el variables.tf de Terraform para escalar a una instancia Compute Optimized (c7i-flex.large con 4 GB RAM).

    Problema: disk I/O error: no space left on device en K3s.

    Causa: El disco raíz por defecto de la instancia era de 2 GB. Al descargar imágenes de K8s, ArgoCD y Prometheus, el disco se llenó al 100%.

    Solución: Se limpiaron logs (journalctl --vacuum-time=2d) y se modificó main.tf para añadir un bloque root_block_device con 20 GB de capacidad y tipo gp3. Como Terraform no puede redimensionar en caliente sin destruir, se hizo un terraform destroy + apply.

3. Redes y Accesos

    Problema: dial tcp ***:22: i/o timeout en GitHub Actions.

    Causa: El Security Group de AWS solo permitía SSH desde la IP pública del desarrollador. GitHub Actions usa IPs dinámicas.

    Solución: Se modificó la regla de entrada en el Security Group (task-api-sg) para permitir el puerto 22 desde 0.0.0.0/0 (en entorno de pruebas).

    Problema: ssh: unable to authenticate, attempted methods [none publickey].

    Causa: El secreto EC2_SSH_KEY en GitHub estaba corrupto o el usuario era incorrecto (se puso ec2_user en lugar de ec2-user).

    Solución: Se regeneró el secreto copiando el archivo .pem completo y se corrigió el typo en el secreto EC2_USER.

    Problema: The connection to the server 127.0.0.1:6443 was refused.

    Causa: kubectl intentaba buscar el clúster en localhost porque no encontraba el archivo kubeconfig o el proceso de K3s se había caído.

    Solución: Se forzó la exportación de la variable en el deploy.yml (export KUBECONFIG=/home/ec2-user/.kube/config) y se regeneró el archivo copiándolo de /etc/rancher/k3s/k3s.yaml.

4. Contenedores y Kubernetes

    Problema: CreateContainerConfigError en los Pods de Postgres y Task-API.

    Causa: Los Pods intentaban leer variables de entorno desde un Secret de Kubernetes (postgres-secret) que no existía en el clúster.

    Solución: Se ejecutó kubectl create secret generic manualmente y luego se integró esta creación en el script de arranque (user_data.sh) y en el pipeline de CI/CD.

    Problema: ImagePullBackOff (implícito).

    Causa: El paquete en GitHub Container Registry (GHCR) era privado y Kubernetes no tenía credenciales para descargarlo.

    Solución: Se cambió la visibilidad del paquete a "Público" desde la configuración del repositorio en GitHub.

    Problema: Run Command Timeout en GitHub Actions durante kubectl rollout status.

    Causa: El comando espera a que el Pod viejo muera y el nuevo arranque. Si hay problemas de memoria o el Pod viejo está atascado, el pipeline se queda esperando y GitHub corta la conexión a los 10 minutos.

    Solución: Se eliminó kubectl rollout status del pipeline y se añadió kubectl delete pod -l app=task-api --ignore-not-found=true antes del apply para forzar la limpieza de réplicas huérfanas.

5. GitOps y Enrutamiento (ArgoCD y Traefik)

    Problema: ArgoCD se quedaba en estado Unknown o ComparisonError.

    Causa: El secreto argocd-repo-creds no estaba bien formado o no tenía la etiqueta correcta (argocd.argoproj.io/secret-type: repo-creds). Además, se estaba usando la clave pública por error en lugar de la privada.

    Solución: Se generó el secreto directamente desde el archivo de clave privada (--from-file=sshPrivateKey=argocd-key) y se etiquetó correctamente.

    Problema: 404 Not Found al intentar acceder a ArgoCD por la IP pública.

    Causa: La API (Task-API) tenía un Ingress en la ruta /, por lo que Traefik enviaba todas las peticiones a la API. ArgoCD no tenía ruta asignada o competía por la raíz.

    Solución: Se modificó el Ingress de ArgoCD para que escuchara en el subdirectorio /argocd y se configuró ArgoCD (server.rootpath y server.basehref) para que supiera que vive en un subdirectorio.

Conclusión del Desarrollador:
"Este proyecto me ha enseñado que en DevOps, el 20% del tiempo se escribe código y el 80% se dedica a entender por qué la red no enruta, por qué falta un byte en un archivo YAML o por qué Linux ha decidido matar un proceso silenciosamente. La resiliencia y el método de diagnóstico son las herramientas más valiosas."

