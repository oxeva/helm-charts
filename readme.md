Oxeva helm charts
====================

Charts HELM used by [Oxeva](https://www.oxeva.fr) to deploy its services.
Feel free to use them as you wish.

This project was initiated in july 2025 with Bitnami politic change to their helm images.
because Helm charts are heavily tied to bitnami images, we decided to create our own charts from scratch, and try to keep compatibility with original values.yaml files. But be aware that all options are not implemented.
Check values.yaml files for more information.

Release a new version (internal note)
----------------------------------
You need a personal token (https://github.com/settings/personal-access-tokens/new) with access to this repository.
change "resource owner" to oxeva, then in "repository access" select specific repository `oxeva/helm-charts`.
For permissions you need Contents => ALL
put this in `.env`: 
```
CR_TOKEN=xxxxxx
```
Then load it : 
```
source .env
```


1. Update the version in `Chart.yaml`
2. Update the version in `values.yaml`
3. Use project https://github.com/helm/chart-releaser
4. Create package : 
```
docker run --rm -it -e CR_TOKEN=$CR_TOKEN -v $(pwd):/project quay.io/helmpack/chart-releaser package -w /project -e HOME=/project /project/phpmyadmin
```
5. Upload package to github:
```
docker run --rm -it -e CR_TOKEN=$CR_TOKEN -v $(pwd):/project quay.io/helmpack/chart-releaser upload -w /project -e HOME=/project /project/phpmyadmin
```
6. Publish index on github:
```
docker run --rm -it -e GIT_CONFIG_COUNT=1 -e GIT_CONFIG_KEY_0=safe.directory -e GIT_CONFIG_VALUE_0=/project -e CR_TOKEN=$CR_TOKEN -w /project -e HOME=/project -v $(pwd):/project quay.io/helmpack/chart-releaser index --config /project/.cr.yaml --index-path . --packages-with-index --push
```