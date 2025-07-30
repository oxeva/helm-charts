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
cr package --config .cr.yaml ./folder
```
5. Upload package to github:
```
cr upload --config .cr.yaml --token=$CR_TOKEN ./folder
```
6. Publish index on github:
```
cr index --config /project/.cr.yaml --index-path . --packages-with-index --push
```
NOTE: buggy because of https://github.com/helm/chart-releaser/issues/124 ; 
need to manually upload targz + edit index.yaml in branch gh-pages.