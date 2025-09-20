## Kolekce zdrojových balíčků XBPS

Toto úložiště obsahuje kolekci zdrojových balíčků XBPS pro sestavení binárních balíčků pro distribuci Void Linux.

Zahrnutý skript `xbps-src` načte a zkompiluje zdrojové kódy a nainstaluje své soubory do `fake destdir` aby se vygenerovaly binární balíčky XBPS, které lze nainstalovat nebo se na ně lze dotazovat pomocí nástrojů `xbps-install(1)` a `xbps-query(1)` . .

Obecný přehled o tom, jak přispívat, najdete v části [Přispívání](./CONTRIBUTING.md) a podrobnosti o vytváření zdrojových balíčků najdete [v příručce](./Manual.md) .

### Obsah

- [Požadavky](#requirements)
- [Rychlý start](#quick-start)
- [chroot metody](#chroot-methods)
- [Nainstalujte bootstrap balíčky](#install-bootstrap)
- [Konfigurace](#configuration)
- [Hierarchie adresářů](#directory-hierarchy)
- [Stavební balíčky](#building-packages)
- [Možnosti sestavení balíčku](#build-options)
- [Sdílení a podepisování místních úložišť](#sharing-and-signing)
- [Opětovné sestavení a přepsání existujících místních balíčků](#rebuilding)
- [Povolení distcc pro distribuovanou kompilaci](#distcc)
- [Zrcadla Distfiles](#distfiles-mirrors)
- [Křížová kompilace balíčků pro cílovou architekturu](#cross-compiling)
- [Použití xbps-src v zahraniční distribuci Linuxu](#foreign)
- [Předělat masterdir](#remaking-masterdir)
- [Udržujte svůj masterdir aktuální](#updating-masterdir)
- [Vytváření 32bitových balíčků na x86_64](#building-32bit)
- [Nativní vytváření balíčků pro knihovnu musl C](#building-for-musl)
- [Budování prázdného základního systému od nuly](#building-base-system)

### Požadavky

- GNU bash
- xbps &gt;= 0,56
- git(1) - pokud není nakonfigurováno, viz etc/defaults.conf
- běžné nástroje POSIX, které jsou standardně součástí téměř všech systémů UNIX
- curl(1) - vyžaduje `xbps-src update-check`

Pro bootstrapping ze zdrojového kódu navíc:

- flock(1) - util-linux
- bsdtar nebo GNU tar (v tomto pořadí preferencí)
- install(1) - GNU coreutils
- objcopy(1), objdump(1), strip(1): binutils

`xbps-src` vyžaduje [obslužný program pro chroot](#chroot-methods) a svázání připojení existujících adresářů do `masterdir` , který se používá jako jeho hlavní `chroot` adresář. `xbps-src` podporuje více obslužných programů k provedení tohoto úkolu.

> POZNÁMKA: `xbps-src` již neumožňuje sestavení jako root. Použijte jednu z metod chroot.

<a name="quick-start"></a>

### Rychlý start

Klonujte git repozitář `void-packages` :

```
$ git clone https://github.com/void-linux/void-packages.git
$ cd void-packages
```

Bootstrapping z binárních balíčků se provede automaticky při prvním sestavení balíčku, ale lze jej provést ručně pomocí:

```
$ ./xbps-src binary-bootstrap
```

Sestavte balíček zadáním `pkg` a názvu balíčku:

```
$ ./xbps-src pkg <package_name>
```

Pomocí `./xbps-src -h` vypíšete všechny dostupné cíle a možnosti.

Chcete-li sestavit balíčky označené jako 'omezené', upravte `etc/conf` :

```
$ echo XBPS_ALLOW_RESTRICTED=yes >> etc/conf
```

Po sestavení bude balíček dostupný v `hostdir/binpkgs` nebo v příslušném podadresáři (např. `hostdir/binpkgs/nonfree` ). Instalace balíčku:

```
# xbps-install --repository hostdir/binpkgs <package_name>
```

Alternativně lze balíčky nainstalovat pomocí nástroje `xi` z balíčku `xtools` . `xi` bere v úvahu úložiště aktuálního pracovního adresáře.

```
$ xi <package_name>
```

<a name="chroot-methods"></a>

### chroot metody

#### xbps-uunshare(1) (výchozí)

Nástroj XBPS, který používá `user_namespaces(7)` (součást xbps, výchozí bez parametru `-t` ).

Tento nástroj vyžaduje tyto možnosti jádra Linux:

- CONFIG_NAMESPACES
- CONFIG_IPC_NS
- CONFIG_UTS_NS
- CONFIG_USER_NS

Toto je výchozí metoda, a pokud váš systém nepodporuje žádnou z požadovaných voleb jádra, selže s `EINVAL (Invalid argument)` .

#### xbps-uchroot(1)

Nástroj XBPS, který používá `namespaces` a musí být `setgid` (součást xbps).

> POZNÁMKA: Toto je jediná metoda, která implementuje funkci `xbps-src -t` , proto příznak ignoruje volbu provedenou v konfiguračních souborech a povolí `xbps-uchroot` .

Tento nástroj vyžaduje tyto možnosti jádra Linux:

- CONFIG_NAMESPACES
- CONFIG_IPC_NS
- CONFIG_PID_NS
- CONFIG_UTS_NS

Váš uživatel musí být přidán do speciální skupiny, aby mohl používat `xbps-uchroot(1)` a spustitelný soubor musí být `setgid` :

```
# chown root:<group> xbps-uchroot
# chmod 4750 xbps-uchroot
# usermod -a -G <group> <user>
```

> POZNÁMKA: ve výchozím nastavení byste to neměli dělat ručně, váš uživatel musí být členem skupiny `xbuilder` .

Chcete-li to povolit:

```
$ cd void-packages
$ echo XBPS_CHROOT_CMD=uchroot >> etc/conf
```

Pokud se z nějakého důvodu chybuje jako `ERROR clone (Operation not permitted)` , zkontrolujte, zda je váš uživatel členem požadované `group` a že nástroj `xbps-uchroot(1)` má správná oprávnění a vlastníka/skupinu, jak je vysvětleno výše.

#### bwrap (1)

bubblewrap, sandboxingový nástroj pro neprivilegované uživatele, který používá uživatelské jmenné prostory nebo setuid. Viz [https://github.com/containers/bubblewrap](https://github.com/containers/bubblewrap) .

#### éterický

Zničí hostitelský systém, na kterém běží. Užitečné pouze pro jednorázové kontejnery, tj. docker (používá se s CI).

<a name="install-bootstrap"></a>

### Nainstalujte bootstrap balíčky

Existuje sada balíčků, které tvoří počáteční kontejner sestavení, nazývaný `bootstrap` . Tyto balíčky se instalují do `masterdir` za účelem vytvoření kontejneru.

Primárním a doporučeným způsobem nastavení tohoto kontejneru je použití příkazu `binary-bootstrap` . Použije se již existující binární balíčky, buď ze vzdálených repozitářů `xbps` , nebo z vašeho lokálního repozitáře. To se provádí automaticky při sestavování balíčků, pokud neexistuje inicializovaný hlavní adresář pro hostitelskou architekturu.

K dispozici je také příkaz `bootstrap` , který vytvoří všechny potřebné `bootstrap` balíčky od začátku. To se obvykle nedoporučuje, protože tyto balíčky jsou sestaveny pomocí toolchainu vašeho hostitelského systému a nejsou ani plně vybavené ani reprodukovatelné (váš hostitelský systém může ovlivnit sestavení), a proto by měly být použity pouze jako fáze 0 pro bootstraping nových Void systémů.

Pokud se přesto rozhodnete použít `bootstrap` , použijte výsledný kontejner fáze 0 k opětovnému sestavení všech balíčků `bootstrap` , poté použijte `binary-bootstrap` (fáze 1) a znovu sestavte balíčky `bootstrap` (pro získání fáze 2 a poté znovu použijte `binary-bootstrap` ). Jakmile to uděláte, budete mít sadu `bootstrap` ekvivalentní použití `binary-bootstrap` .

Také mějte na paměti, že `bootstrap` úplného zdroje je časově náročné a bude vyžadovat instalaci řady utilit ve vašem hostitelském systému, jako jsou `binutils` , `gcc` , `perl` , `texinfo` a další.

### Konfigurace

Soubor `etc/defaults.conf` obsahuje možná nastavení, která lze přepsat pomocí konfiguračního souboru `etc/conf` pro obslužný program `xbps-src` ; pokud tento soubor neexistuje, pokusí se načíst konfigurační nastavení z `$XDG_CONFIG_HOME/xbps-src.conf` , `~/.config/xbps-src.conf` , `~/.xbps-src.conf` .

Pokud chcete upravit výchozí `CFLAGS` , `CXXFLAGS` a `LDFLAGS` , nepřepisujte ty definované v `etc/defaults.conf` , nastavte je na `etc/conf` , tj.

```
$ echo 'XBPS_CFLAGS="your flags here"' >> etc/conf
$ echo 'XBPS_LDFLAGS="your flags here"' >> etc/conf
```

Nativní a křížový kompilátor/linker příznaky jsou nastaveny pro architekturu v `common/build-profiles` a `common/cross-profiles` . V ideálním případě jsou tato nastavení ve výchozím nastavení dostatečně dobrá a není třeba nastavovat vlastní, pokud nevíte, co děláte.

#### Virtuální balíčky

Soubor `etc/defaults.virtual` obsahuje výchozí náhrady za virtuální balíčky, které se používají jako závislosti ve stromu zdrojových balíčků.

Pokud chcete tyto náhrady přizpůsobit, zkopírujte `etc/defaults.virtual` do `etc/virtual` a upravte jej podle svých potřeb.

<a name="directory-hierarchy"></a>

### Hierarchie adresářů

S výchozím konfiguračním souborem se používá následující hierarchie adresářů:

```
     /void-packages
        |- common
        |- etc
        |- srcpkgs
        |  |- xbps
        |     |- template
        |
        |- hostdir
        |  |- binpkgs ...
        |  |- ccache ...
        |  |- distcc-<arch> ...
        |  |- repocache ...
        |  |- sources ...
        |
        |- masterdir-<arch>
        |  |- builddir -> ...
        |  |- destdir -> ...
        |  |- host -> bind mounted from <hostdir>
        |  |- void-packages -> bind mounted from <void-packages>
```

Popis těchto adresářů je následující:

- `masterdir-<arch>` : hlavní adresář, který má být použit jako rootfs k sestavení/instalaci balíčků.
- `builddir` : k rozbalení tarballů se zdrojovými kódy a umístění balíčků.
- `destdir` : k instalaci balíčků alias **fake destdir** .
- `hostdir/ccache` : k ukládání dat ccache, pokud je povolena volba `XBPS_CCACHE` .
- `hostdir/distcc-<arch>` : k ukládání dat distcc, pokud je povolena volba `XBPS_DISTCC` .
- `hostdir/repocache` : k ukládání binárních balíčků ze vzdálených úložišť.
- `hostdir/sources` : k uložení zdrojů balíčků.
- `hostdir/binpkgs` : místní úložiště pro ukládání generovaných binárních balíčků.

<a name="building-packages"></a>

### Stavební balíčky

Nejjednodušší forma sestavení balíčku se dosáhne spuštěním cíle `pkg` v `xbps-src` :

```
$ cd void-packages
$ ./xbps-src pkg <pkgname>
```

Po vytvoření balíčku a jeho požadovaných závislostí budou binární balíčky vytvořeny a zaregistrovány ve výchozím místním úložišti na `hostdir/binpkgs` ; cestu k tomuto lokálnímu úložišti lze přidat do libovolného konfiguračního souboru xbps (viz xbps.d(5)) nebo je explicitně přidat pomocí cmdline, tj.

```
$ xbps-install --repository=hostdir/binpkgs ...
$ xbps-query --repository=hostdir/binpkgs ...
```

Ve výchozím nastavení se **xbps-src** pokusí vyřešit závislosti balíčků v tomto pořadí:

- Pokud v místním úložišti existuje závislost, použijte ji ( `hostdir/binpkgs` ).
- Pokud ve vzdáleném úložišti existuje závislost, použijte ji.
- Pokud ve zdrojovém balíčku existuje závislost, použijte ji.

Použitím vzdálených úložišť je možné se zcela vyhnout použitím parametru `-N` .

> Výchozí místní úložiště může obsahovat více *dílčích repozitářů* : `debug` , `multilib` atd.

<a name="build-options"></a>

### Možnosti sestavení balíčku

Podporované možnosti sestavení pro zdrojový balíček lze zobrazit pomocí `xbps-src show-options` :

```
$ ./xbps-src show-options foo
```

Možnosti sestavení lze povolit pomocí parametru `-o` `xbps-src` :

```
$ ./xbps-src -o option,option1 pkg foo
```

Možnosti sestavení lze zakázat jejich přidáním předponu `~` :

```
$ ./xbps-src -o ~option,~option1 pkg foo
```

Oba způsoby lze použít společně k povolení a/nebo zakázání více možností současně s `xbps-src` :

```
$ ./xbps-src -o option,~option1,~option2 pkg foo
```

Možnosti sestavení lze také zobrazit pro binární balíčky pomocí `xbps-query(1)` :

```
$ xbps-query -R --property=build-options foo
```

> POZNÁMKA: Pokud vytvoříte balíček s vlastní možností a tento balíček je dostupný v oficiálním neplatném úložišti, aktualizace bude tyto možnosti ignorovat. Přepněte tento balíček do režimu `hold` pomocí `xbps-pkgdb(1)` , tj. `xbps-pkgdb -m hold foo` pro ignorování aktualizací pomocí `xbps-install -u` . Jakmile je balíček `hold` , jediný způsob, jak jej aktualizovat, je explicitně jej deklarovat: `xbps-install -u foo` .

Trvalé globální možnosti sestavení balíčku lze nastavit pomocí proměnné `XBPS_PKG_OPTIONS` v konfiguračním souboru `etc/conf` . Možnosti sestavení pro jednotlivé balíčky lze nastavit pomocí `XBPS_PKG_OPTIONS_<pkgname>` .

> POZNÁMKA: Pokud `pkgname` obsahuje `dashes` , měly by být nahrazeny `underscores` , tj `XBPS_PKG_OPTIONS_xorg_server=opt` .

Seznam podporovaných voleb sestavení balíčku a jeho popis je definován v souboru `common/options.description` nebo v souboru `template` .

<a name="sharing-and-signing"></a>

### Sdílení a podepisování místních úložišť

Chcete-li vzdáleně sdílet místní úložiště, je nutné jej podepsat a binární balíčky v něm uložené. Toho lze dosáhnout pomocí nástroje `xbps-rindex(1)` .

Nejprve je třeba vytvořit klíč RSA pomocí `openssl(1)` nebo `ssh-keygen(1)` :

```
$ openssl genrsa -des3 -out privkey.pem 4096
```

nebo

```
$ ssh-keygen -t rsa -b 4096 -m PEM -f privkey.pem
```

> xbps aktuálně přijímá pouze klíče RSA ve formátu PEM.

Jakmile je soukromý klíč RSA připraven, můžete jej použít k inicializaci metadat úložiště:

```
$ xbps-rindex --sign --signedby "I'm Groot" --privkey privkey.pem $PWD/hostdir/binpkgs
```

A pak udělejte podpis na balíček:

```
$ xbps-rindex --sign-pkg --privkey privkey.pem $PWD/hostdir/binpkgs/*.xbps
```

> Pokud není --privkey nastaveno, výchozí je `~/.ssh/id_rsa` .

Pokud byl klíč RSA chráněn přístupovou frází, budete ji muset zadat nebo ji nastavit pomocí proměnné prostředí `XBPS_PASSPHRASE` .

Jakmile jsou binární balíčky podepsány, zkontrolujte, zda úložiště obsahuje příslušný `hex fingerprint` :

```
$ xbps-query --repository=hostdir/binpkgs -vL
...
```

Pokaždé, když je vytvořen binární balíček, musí být vytvořen podpis balíčku pomocí `--sign-pkg` .

> Není možné podepsat úložiště pomocí více RSA klíčů.

Pokud jsou podepsány balíčky v `hostdir/binpkgs` , klíč ve formátu `.plist` (importovaný xbps) lze umístit do `etc/repo-keys/` aby xbps-src nevyzval k importu tohoto klíče.

<a name="rebuilding"></a>

### Opětovné sestavení a přepsání existujících místních balíčků

Balíčky se při každém sestavení přepisují, aby bylo získání balíčku se změněnými možnostmi sestavení snadné. Aby xbps-src přeskočilo sestavení a zachovalo první sestavení balíčku s danou verzí a revizí, stejně jako v oficiálním neplatném repozitáři, nastavte `XBPS_PRESERVE_PKGS=yes` v souboru `etc/conf` .

Přeinstalaci balíčku do cílového `rootdir` lze také snadno provést:

```
$ xbps-install --repository=/path/to/local/repo -yf xbps-0.25_1
```

Dvojité použití parametru `-f` přepíše konfigurační soubory.

> Vezměte prosím na vědomí, že `package expression` musí být správně definován, aby bylo možné balík explicitně vyzvednou z požadovaného úložiště.

<a name="distcc"></a>

### Povolení distcc pro distribuovanou kompilaci

Nastavte pracovníky (stroje, které budou kompilovat kód):

```
# xbps-install -Sy distcc
```

Aktualizace whitelistu kompilátoru distcc

```
# update-distcc-symlinks
```

Upravte konfiguraci tak, aby vaše místní síťové počítače mohly používat distcc (např. `192.168.2.0/24` ):

```
# echo "192.168.2.0/24" >> /etc/distcc/clients.allow
```

Povolte a spusťte službu `distccd` :

```
# ln -s /etc/sv/distccd /var/service
```

Nainstalujte distcc také na hostitele (stroj, který spouští xbps-src). Pokud nechcete používat hostitele jako pracovníka z jiných počítačů, není třeba upravovat konfiguraci.

Na hostiteli nyní můžete povolit distcc v souboru `void-packages/etc/conf` :

```
XBPS_DISTCC=yes
XBPS_DISTCC_HOSTS="localhost/2 --localslots_cpp=24 192.168.2.101/9 192.168.2.102/2"
XBPS_MAKEJOBS=16
```

Hodnoty příkladu předpokládají CPU localhost se 4 jádry, z nichž nejvýše 2 se používají pro úlohy kompilátoru. Počet slotů pro úlohy preprocesoru je nastaven na 24, aby bylo k dispozici dostatek předzpracovaných dat pro ostatní CPU ke kompilaci. Pracovník 192.168.2.101 má CPU s 8 jádry a /9 pro počet úloh je saturující volba. Pracovník 192.168.2.102 je nastaven tak, aby spouštěl maximálně 2 kompilační úlohy, aby byla jeho zátěž nízká, i když má CPU 4 jádra. Nastavení XBPS_MAKEJOBS je zvýšeno na 16, aby se zohlednil možný paralelismus (2 + 9 + 2 + určitá prodleva).

<a name="distfiles-mirrors"></a>

### Zrcadla Distfiles

V etc/conf můžete volitelně definovat zrcadlo nebo seznam zrcadel pro vyhledávání souborů distfiles.

```
$ echo 'XBPS_DISTFILES_MIRROR="ftp://192.168.100.5/gentoo/distfiles"' >> etc/conf
```

Pokud má být prohledáno více než jedno zrcadlo, můžete buď zadat více adres URL oddělených mezerami, nebo přidat do proměnné takto

```
$ echo 'XBPS_DISTFILES_MIRROR+=" https://sources.voidlinux.org/"' >> etc/conf
```

V tomto případě nezapomeňte za první dvojitou uvozovku vložit mezeru.

Zrcadla jsou prohledána, aby distfiles vytvořily balíček, dokud kontrolní součet staženého souboru neodpovídá tomu, který je uveden v šabloně.

Nakonec, pokud žádné zrcadlo nenese distfile, nebo v případě, že všechna stahování selhala při ověření kontrolního součtu, použije se původní umístění stahování.

Pokud pro XBPS_CHROOT_CMD používáte `uchroot` , můžete také zadat místní cestu pomocí předpony `file://` nebo jednoduše absolutní cestu na hostiteli sestavení (např. /mnt/distfiles). Takto zadaná zrcadlová umístění jsou připojena do chrootového prostředí pod $XBPS_MASTERDIR a vyhledávají distfiles stejně jako vzdálená umístění.

<a name="cross-compiling"></a>

### Křížová kompilace balíčků pro cílovou architekturu

V současné době může `xbps-src` křížit sestavení balíčků pro některé cílové architektury pomocí křížového kompilátoru. Podporovaný cíl je zobrazen pomocí `./xbps-src -h` .

Pokud byl zdrojový balíček upraven tak, aby byl **křížově sestavitelný,** `xbps-src` automaticky sestaví binární balíčky pomocí jednoduchého příkazu:

```
$ ./xbps-src -a <target> pkg <pkgname>
```

Pokud sestavení z jakéhokoli důvodu selže, může to být problém nového sestavení nebo jednoduše proto, že nebylo upraveno pro **křížovou kompilaci** .

<a name="foreign"></a>

### Použití xbps-src v zahraniční distribuci Linuxu

xbps-src lze použít v jakékoli nedávné distribuci Linuxu odpovídající architektuře CPU.

Chcete-li použít xbps-src ve vaší distribuci Linuxu, postupujte podle následujících pokynů. Začněme stahovat statické binární soubory xbps:

```
$ wget http://repo-default.voidlinux.org/static/xbps-static-latest.<arch>-musl.tar.xz
$ mkdir ~/XBPS
$ tar xvf xbps-static-latest.<arch>-musl.tar.xz -C ~/XBPS
$ export PATH=~/XBPS/usr/bin:$PATH
```

Pokud `xbps-uunshare` nefunguje kvůli nedostatku podpory `user_namespaces(7)` , zkuste jiné [chroot metody](#chroot-methods) .

Naklonujte `void-packages` git repozitář:

```
$ git clone https://github.com/void-linux/void-packages.git
```

a `xbps-src` by měl být plně funkční; volitelně spusťte proces `bootstrap` , tj.:

```
$ ./xbps-src binary-bootstrap
```

Výchozí masterdir je vytvořen v aktuálním pracovním adresáři, tj `void-packages/masterdir-<arch>` , kde `<arch>` pro výchozí masterdir je nativní architektura xbps.

<a name="remaking-masterdir"></a>

### Předělat masterdir

Pokud z nějakého důvodu musíte aktualizovat xbps-src a cíl `bootstrap-update` nestačí, je možné znovu vytvořit masterdir pomocí dvou jednoduchých příkazů (všimněte si prosím, že `zap` udržuje vaše adresáře `ccache/distcc/host` nedotčené):

```
$ ./xbps-src zap
$ ./xbps-src binary-bootstrap
```

<a name="updating-masterdir"></a>

### Udržujte svůj masterdir aktuální

Někdy musí být balíčky bootstrap aktualizovány na nejnovější dostupnou verzi v repozitářích, to se provádí pomocí cíle `bootstrap-update` :

```
$ ./xbps-src bootstrap-update
```

<a name="building-32bit"></a>

### Vytváření 32bitových balíčků na x86_64

K sestavení 32bitových balíčků na x86_64 jsou k dispozici dva způsoby:

- nativní režim s 32bitovým masterdirem (doporučeno, používá se v oficiálním úložišti)
- režim křížové kompilace na [cíl](#cross-compiling) i686

Kanonický režim (nativní) potřebuje nový x86 `masterdir` , který se vytvoří při sestavování balíčku pro i686:

```
$ ./xbps-src -A i686 ...
```

<a name="building-for-musl"></a>

### Nativní vytváření balíčků pro knihovnu musl C

Kanonický způsob sestavování balíčků pro stejnou architekturu, ale s jinou knihovnou C, je pomocí vyhrazeného hlavního adresáře (masterdir) s použitím příznaku architektury hostitele `-A` . Pro sestavení pro x86_64-musl na systému glibc x86_64 použijte `-A x86_64-musl` ve volání `xbps-src` . Tím se vytvoří a nabootuje nový hlavní adresář s názvem `masterdir-x86_64-musl` , který bude použit, když je zadán `-A x86_64-musl` :

```
$ ./xbps-src -A x86_64-musl pkg ...
```

<a name="building-base-system"></a>

### Budování prázdného základního systému od nuly

Chcete-li znovu sestavit všechny balíčky v `base-system` pro vaši nativní architekturu:

```
$ ./xbps-src -N pkg base-system
```

Je také možné křížově kompilovat vše od začátku:

```
$ ./xbps-src -a <target> -N pkg base-system
```

Po dokončení sestavení můžete zadat cestu k místnímu úložišti `void-mklive` , tj.

```
# cd void-mklive
# make
# ./mklive.sh ... -r /path/to/hostdir/binpkgs
```
