## void-packages buildroot kontejnery

Tyto kontejnery se používají pro CI a měly by obsahovat vše potřebné ke spuštění xbps-src.

### Aktualizace

Chcete-li sestavit novou verzi, spusťte běh CI tak, že něco přesunete do `common/container/` na `master` nebo pomocí tlačítka `Run workflow` [zde](https://github.com/void-linux/void-packages/actions/workflows/container.yaml) .

Jakmile je toto vytvořeno, aktualizujte verzi, kde se používá v `.github/workflows/` (obvykle v hodnotě klíče `container.image` ), na nově vytvořenou značku.
