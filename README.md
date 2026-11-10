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

