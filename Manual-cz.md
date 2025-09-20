# Manuál ke zdrojovým balíčkům XBPS

Tento článek obsahuje vyčerpávající návod, jak vytvořit nové zdrojové balíčky pro XBPS, nativní balíčkovací systém `Void Linux` .

*Obsah*

- Manuál ke zdrojovým balíčkům XBPS
    - [Úvod](#Introduction)
    - [Fáze sestavení balíčku](#buildphase)
    - [Konvence pojmenovávání balíčků](#namingconventions)
        - [Knihovny](#libs)
        - [Jazykové moduly](#language_modules)
        - [Jazykové vazby](#language_bindings)
        - [Programy](#programs)
    - [Globální funkce](#global_funcs)
    - [Globální proměnné](#global_vars)
    - [Dostupné proměnné](#available_vars)
        - [Povinné proměnné](#mandatory_vars)
        - [Nepovinné proměnné](#optional_vars)
        - [O závislých proměnných](#explain_depends)
    - [Úložiště](#repositories)
        - [Repozitáře definované větví](#repo_by_branch)
        - [Repozitáře definované balíčky](#pkg_defined_repo)
    - [Kontrola nových upstream vydání](#updates)
    - [Manipulace s náplastmi](#patches)
    - [Vytvářejte stylové skripty](#build_scripts)
    - [Vytvářejte pomocné skripty](#build_helper)
    - [Funkce](#functions)
    - [Možnosti sestavení](#build_options)
    - [INSTALOVAT a ODEBRAT soubory](#install_remove_files)
    - [INSTALL.msg a REMOVE.msg soubory](#install_remove_files_msg)
    - [Vytváření systémových účtů/skupin za běhu](#runtime_account_creation)
    - [Psaní runitových služeb](#writing_runit_services)
    - [32bitové balíčky](#32bit_pkgs)
    - [Dílčí balíčky](#pkgs_sub)
    - [Některé třídy balíčků](#pkgs_classes)
        - [Vývojové balíčky](#pkgs_development)
        - [Datové balíčky](#pkgs_data)
        - [Balíčky dokumentace](#pkgs_documentation)
        - [Python balíčky](#pkgs_python)
        - [Přejít na balíčky](#pkgs_go)
        - [Haskell balíčky](#pkgs_haskell)
        - [Balíčky písem](#pkgs_font)
    - [Přejmenování balíčku](#pkg_rename)
    - [Odebírání balíčku](#pkg_remove)
    - [Spouštěče XBPS](#xbps_triggers)
        - [appstream-cache](#triggers_appstream_cache)
        - [binfmts](#triggers_binfmts)
        - [dkms](#triggers_dkms)
        - [schémata gconf](#triggers_gconf_schemas)
        - [gdk-pixbuf-loadery](#triggers_gdk_pixbuf_loaders)
        - [gio-moduly](#triggers_gio_modules)
        - [získávání-schémata](#triggers_gsettings_schemas)
        - [gtk-ikona-mezipaměť](#triggers_gtk_icon_cache)
        - [gtk-immodules](#triggers_gtk_immodules)
        - [gtk-pixbuf-loadery](#triggers_gtk_pixbuf_loaders)
        - [gtk3-immodules](#triggers_gtk3_immodules)
        - [hwdb.d-dir](#triggers_hwdb.d_dir)
        - [info-soubory](#triggers_info_files)
        - [initramfs-regenerate](#triggers_initramfs_regenerate)
        - [kernel-háky](#triggers_kernel_hooks)
        - [mimedb](#triggers_mimedb)
        - [mkdirs](#triggers_mkdirs)
        - [pango-moduly](#triggers_pango_module)
        - [pycompile](#triggers_pycompile)
        - [registr-shell](#triggers_register_shell)
        - [systémové účty](#triggers_system_accounts)
        - [texmf-dist](#triggers_texmf_dist)
        - [update-desktopdb](#triggers_update_desktopdb)
        - [x11-fonty](#triggers_x11_fonts)
        - [xml-katalog](#triggers_xml_catalog)
    - [Zrušte konkrétní dokumentaci](#documentation)
    - [Poznámky](#notes)
    - [Přispívání přes git](#contributing)
    - [Pomoc](#help)

<a id="Introduction"></a>

### Úvod

Úložiště `void-packages` obsahuje všechny recepty ke stažení, kompilaci a sestavování binárních balíčků pro Void Linux. Tyto soubory `source` balíčků se nazývají `templates` .

Soubory `template` jsou skripty shellu, které definují `variables` a `functions` , které má zpracovat `xbps-src` , tvůrce balíčků, za účelem generování binárních balíčků. Shell používaný `xbps-src` je GNU bash; `xbps-src` si neklade za cíl být kompatibilní s POSIX `sh` .

Podle konvence všechny šablony začínají komentářem, který říká, že se jedná o `template file` pro určitý balíček. Většina řádků by měla mít méně než 80 sloupců; proměnné, které vypisují mnoho hodnot, lze rozdělit na nové řádky, přičemž pokračování na dalším řádku je odsazeno o jednu mezeru.

Jednoduchý příklad `template` je následující:

```
# Template file for 'foo'
pkgname=foo
version=1.0
revision=1
build_style=gnu-configure
short_desc="Package description, no more than 72 characters"
maintainer="name <email>"
license="GPL-3.0-or-later"
homepage="http://www.foo.org"
distfiles="http://www.foo.org/foo-${version}.tar.gz"
checksum="fea0a94d4b605894f3e2d5572e3f96e4413bcad3a085aae7367c2cf07908b2ff"
```

Soubor šablony obsahuje definice ke stažení, sestavení a instalaci souborů balíčků do `fake destdir` a poté lze vygenerovat binární balíček s definicemi v něm uvedenými.

Nedělejte si starosti, pokud něco není jasné, jak by mělo být. Rezervované `variables` a `functions` budou vysvětleny později. Tento soubor `template` by měl být vytvořen v adresáři, který odpovídá `$pkgname` , Příklad: `void-packages/srcpkgs/foo/template` .

Pokud po běhu vše proběhlo v pořádku

```
$ ./xbps-src pkg <pkgname>
```

v místním úložišti `hostdir/binpkgs` bude vygenerován binární balíček s názvem `foo-1.0_1.<arch>.xbps`

<a id="buildphase"></a>

### Fáze sestavení balíčku

Sestavení balíčku se skládá z následujících fází:

- `setup` Tato fáze připravuje prostředí pro sestavení balíčku.

- `fetch` Tato fáze stáhne požadované zdroje pro `source package` , jak je definováno proměnnou `distfiles` nebo funkcí `do_fetch()` .

- `extract` Tato fáze rozbalí soubory `distfiles` do `$wrksrc` nebo spustí funkci `do_extract()` , což je adresář, který se má použít ke kompilaci `source package` .

- `patch` Tato fáze aplikuje všechny záplaty v adresáři záplat balíčku a lze ji použít k provedení dalších operací před konfigurací balíčku.

- `configure` Tato fáze provede `configuration` `source package` , tj. `GNU configure scripts` .

- `build` Tato fáze zkompiluje/připraví `source files` pomocí `make` nebo jiné kompatibilní metody.

- `check` Tato volitelná fáze kontroluje výsledek fáze `build` spuštěním testovací sady, kterou balíček poskytuje. Pokud výchozí funkce `do_check` poskytovaná stylem sestavení nic nedělá, šablona by měla vhodně nastavit `make_check_target` a/nebo `make_check_args` nebo definovat svou vlastní funkci `do_check` . Pokud testy trvají příliš dlouho nebo se nedají spustit ve všech prostředích, `make_check` by měl být nastaven na odpovídající hodnotu nebo `do_check` by měl být přizpůsoben tak, aby omezil testovací sadu, pokud není `XBPS_CHECK_PKGS` `full` .

- `install` Tato fáze nainstaluje `package files` do balíčku destdir `<masterdir>/destdir/<pkgname>-<version>` , pomocí `make install` nebo jakoukoli jinou kompatibilní metodou.

- `pkg` Tato fáze vytvoří `binary packages` se soubory uloženými v `package destdir` a zaregistruje je do místního úložiště.

- `clean` Tato fáze vyčistí balíček (pokud je definován).

`xbps-src` podporuje spuštění pouze zadané fáze, a pokud proběhla úspěšně, fáze bude později přeskočena (pokud její pracovní adresář `${wrksrc}` nebude odstraněn pomocí `xbps-src clean` ).

<a id="namingconventions"></a>

### Konvence pojmenovávání balíčků

<a id="libs"></a>

#### Knihovny

Knihovny jsou balíčky, které poskytují sdílené objekty (*.so) v /usr/lib. Měly by být pojmenovány jako jejich název upstream balíčku s následujícími výjimkami:

- Balíček je dílčím balíčkem frontendové aplikace a poskytuje sdílené objekty používané základním balíčkem a dalšími knihovnami třetích stran. V takovém případě by měl mít předponu 'lib'. Výjimka z tohoto pravidla je: Pokud je spustitelný soubor použit pouze pro sestavení tohoto balíčku, přesune se do balíčku -devel.

Příklad: wireshark -&gt; subpkg libwireshark

Knihovny musí být rozděleny do dvou dílčích balíčků: `<name>` a `<name>-devel` .

- `<name>` by mělo obsahovat pouze ty části balíčku, které jsou potřebné ke spuštění propojeného programu.

- `<name>-devel` by měl obsahovat všechny soubory, které jsou potřeba ke kompilaci balíčku proti tomuto balíčku. Pokud je knihovna dílčím balíčkem, měl by se jeho odpovídající vývojový balíček jmenovat `lib<name>-devel`

<a id="language_modules"></a>

#### Jazykové moduly

Jazykové moduly jsou rozšířením skriptovacích nebo kompilovaných jazyků. Tyto balíčky samy o sobě neposkytují žádné spustitelné soubory, ale mohou je používat jiné balíčky napsané ve stejném jazyce.

Konvence pojmenování těchto balíčků je:

```
<language>-<name>
```

Pokud balíček obsahuje modul i spustitelný soubor, měl by být rozdělen na balíček poskytující spustitelný soubor s názvem `<name>` a modul s názvem `<language>-<name>` . Pokud balíček začíná samotným názvem jazyků, lze předponu jazyka vypustit. Krátké názvy jazyků nejsou platnou náhradou jazykové předpony.

Example: perl-URI, python3-pyside2

<a id="language_bindings"></a>

#### Jazykové vazby

Jazykové vazby jsou balíčky, které umožňují programům nebo knihovnám mít rozšíření nebo zásuvné moduly napsané v určitém jazyce.

Konvence pojmenování těchto balíčků je:

```
<name>-<language>
```

Example: gimp-python3, irssi-perl

<a id="programs"></a>

#### Programy

Programy ukládají spustitelné soubory do /usr/bin (nebo ve velmi speciálních případech do jiných .../bin adresářů)

U těchto balíčků by měl být použit název upstream balíčků. Pamatujte, že na rozdíl od mnoha jiných distribucí, void nepíše názvy balíčků malými písmeny. Obecně platí, že pokud tar.gz balíku obsahuje velká písmena, pak by je měl obsahovat i název balíku; pokud tomu tak není, název balíčku je malá písmena.

Programy lze rozdělit na balíčky programů a balíčky knihoven. Programový balíček by měl být pojmenován tak, jak je popsáno výše. Balíček knihovny by měl mít předponu "lib" (viz část `Libraries` )

<a id="global_funcs"></a>

### Globální funkce

Následující funkce jsou definovány `xbps-src` a lze je použít na libovolné šabloně:

- *vinstall()* `vinstall <file> <mode> <targetdir> [<name>]`

    Nainstaluje `file` se zadaným `mode` do `targetdir` v pkg `$DESTDIR` . Volitelný 4. argument lze použít ke změně `file name` .

- *vcopy()* `vcopy <pattern> <targetdir>`

    Zkopíruje rekurzivně všechny soubory ve `pattern` do `targetdir` v balíčku `$DESTDIR` .

- *vmove()* `vmove <pattern>`

    Přesune `pattern` do zadaného adresáře v balíčku `$DESTDIR` .

- *vmkdir()* `vmkdir <directory> [<mode>]`

    Vytvoří adresář v pkg `$DESTDIR` . 2. volitelný argument nastavuje režim adresáře.

- *vbin()* `vbin <file> [<name>]`

    Nainstaluje `file` do `usr/bin` v pkg `$DESTDIR` s oprávněním 0755. Volitelný 2. argument lze použít ke změně `file name` .

- *vman()* `vman <file> [<name>]`

    Nainstaluje `file` jako manuálovou stránku. `vman()` analyzuje název a určuje sekci a také lokalizaci. Také transparentně převádí gzipované (.gz) a bzipované (.bz2) manuálové stránky na prostý text. Příklad mapování:

    - `foo.1` -&gt; `${DESTDIR}/usr/share/man/man1/foo.1`
    - `foo.fr.1` -&gt; `${DESTDIR}/usr/share/man/fr/man1/foo.1`
    - `foo.1p` -&gt; `${DESTDIR}/usr/share/man/man1/foo.1p`
    - `foo.1.gz` -&gt; `${DESTDIR}/usr/share/man/man1/foo.1`
    - `foo.1.bz2` -&gt; `${DESTDIR}/usr/share/man/man1/foo.1`

- *vdoc()* `vdoc <file> [<name>]`

    Nainstaluje `file` do `usr/share/doc/<pkgname>` v balíčku `$DESTDIR` . Volitelný 2. argument lze použít ke změně `file name` .

- *vconf()* `vconf <file> [<name>]`

    Nainstaluje `file` do `etc` v pkg `$DESTDIR` . Volitelný 2. argument lze použít ke změně `file name` .

- *vsconf()* `vsconf <file> [<name>]`

    Nainstaluje `file` do `usr/share/examples/<pkgname>` v pkg `$DESTDIR` . Volitelný 2. argument lze použít ke změně `file name` .

- <a id="vlicense"></a>
    *vlicense()* `vlicense <file> [<name>]`

    Nainstaluje `file` do `usr/share/licenses/<pkgname>` v balíčku `$DESTDIR` . Volitelný 2. argument lze použít ke změně `file name` . Podívejte se [na licenci](#var_license) , kdy ji použít.

- *vsv()* `vsv <service> [<facility>]`

    Nainstaluje `service` z `${FILESDIR}` do /etc/sv. Služba musí být adresář obsahující alespoň spouštěcí skript. Všimněte si, že `supervise` symbolický odkaz bude automaticky vytvořen `vsv` a že spouštěcí skript je touto funkcí automaticky proveden jako spustitelný. Další informace o tom, jak vytvořit nový adresář služeb, najdete [v příslušné části FAQ](http://smarden.org/runit/faq.html#create) . Pokud ve `${FILESDIR}/$service` neexistuje, bude automaticky vytvořena podslužba `log` obsahující `exec vlogger -t $service -p $facility` . není-li zadán druhý argument, použije se funkce `daemon` . Další informace o `vlogger` a dostupných hodnotách pro zařízení naleznete [v části vlogger(8)](https://man.voidlinux.org/vlogger.8) .

- *vsed()* `vsed -i <file> -e <regex>`

    Wrapper kolem sed, který kontroluje sha256sum souboru před a po spuštění příkazu sed, aby zjistil případy, ve kterých volání sed nic nezměnilo. Přebírá libovolné množství souborů a regexů opakovaným voláním `-i file` a `-e regex` , musí být specifikován alespoň jeden soubor a jeden regex.

    Všimněte si, že vsed zavolá příkaz sed pro každý zadaný regulární výraz pro každý zadaný soubor v pořadí, v jakém jsou zadány.

- *vcompletion()* `<file> <shell> [<command>]`

    Nainstaluje dokončení shellu ze `file` pro `command` do správného umístění a s příslušným názvem souboru pro `shell` . Pokud `command` není zadán, bude jako výchozí nastaven `pkgname` . Argument `shell` může být jeden z `bash` , `fish` nebo `zsh` .

- *vextract()* `[-C <target directory>] [--no-strip-components|--strip-components=<n>] <file>`

    Extrahuje `file` do `target directory` s odstraněnými `n` adresářovými komponentami. Pokud `target directory` není zadán, použije se jako výchozí pracovní adresář. Pokud není zadáno `--strip-components` nebo `--no-strip-components` , výchozí je `--strip-components=1` .

- *vsrcextract()* `[-C <target directory>] [--no-strip-components|--strip-components=<n>] <file>`

    Extrahuje `$XBPS_SRCDISTDIR/$pkgname-$version/<file>` do `target directory` s `n` odstraněnými komponentami adresáře. Pokud `target directory` není zadán, použije se jako výchozí pracovní adresář. Pokud není zadáno `--strip-components` nebo `--no-strip-components` , výchozí je `--strip-components=1` .

    To je užitečné při použití ve spojení s `skip_extraction` a pro submodulové distfiles.

- *vsrccopy()* `<file>... <target>`

    Zkopíruje `file` z `$XBPS_SRCDISTDIR/$pkgname-$version/` do `target` adresáře a vytvoří `target` , pokud neexistuje.

    To je užitečné při použití ve spojení s `skip_extraction` .

> Zástupné znaky shellu musí být správně uvozovány, Příklad: `vmove "usr/lib/*.a"` .

<a id="global_vars"></a>

### Globální proměnné

Následující proměnné jsou definovány `xbps-src` a lze je použít v jakékoli šabloně:

- `makejobs` Nastavte na `-jX` pokud je definováno `XBPS_MAKEJOBS` , abyste povolili paralelní úlohy s `GNU make` .

- `sourcepkg` Nastaveno na hlavní název balíku, lze jej použít pro shodu s hlavním balíkem spíše než s dalšími názvy binárních balíků.

- `CHROOT_READY` Nastavte, zda je cílový chroot (masterdir) připraven pro sestavení chrootu.

- `CROSS_BUILD` Nastavte, zda `xbps-src` křížově kompiluje balíček.

- `XBPS_CHECK_PKGS` Nastavte, zda bude `xbps-src` spouštět testy pro balíček. Delší testovací sady by měly být spouštěny v `do_check()` pouze pokud je nastaveno na `full` .

- `DESTDIR` Úplná cesta k falešnému destdir používanému zdrojovým balíčkem pkg, nastavená na `<masterdir>/destdir/${sourcepkg}-${version}` .

- `FILESDIR` Úplná cesta k adresáři balíčku `files` , tj. `srcpkgs/foo/files` . Adresář `files` lze použít k uložení dalších souborů, které se mají nainstalovat jako součást zdrojového balíčku.

- `PKGDESTDIR` Úplná cesta k falešnému cílovému adresáři používanému funkcí `pkg_install()` v `subpackages` , nastavená na `<masterdir>/destdir/${pkgname}-${version}` .

- `XBPS_BUILDDIR` Adresář pro uložení `source code` zpracovávaného zdrojového balíčku, nastavte na `<masterdir>/builddir` . Balíček `wrksrc` je vždy uložen v tomto adresáři, například `${XBPS_BUILDDIR}/${wrksrc}` .

- `XBPS_MACHINE` Architektura stroje vrácená `xbps-uhelper arch` .

- `XBPS_ENDIAN` Endianness stroje ("le" nebo "be").

- `XBPS_LIBC` Knihovna C počítače ("glibc" nebo "musl").

- `XBPS_WORDSIZE` Velikost slova stroje v bitech (32 nebo 64).

- `XBPS_NO_ATOMIC8` Stroj postrádá nativní 64bitové atomy (potřebuje emulaci libatomic).

- `XBPS_SRCDISTDIR` Úplná cesta k místu, kde jsou uloženy `source distfiles` , tj. `$XBPS_HOSTDIR/sources` .

- `XBPS_SRCPKGDIR` Úplná cesta k adresáři `srcpkgs` .

- `XBPS_TARGET_MACHINE` Architektura cílového počítače při křížové kompilaci balíčku.

- `XBPS_TARGET_ENDIAN` Endianness cílového počítače ("le" nebo "be").

- `XBPS_TARGET_LIBC` Knihovna C cílového počítače ("glibc" nebo "musl").

- `XBPS_TARGET_WORDSIZE` Velikost slova cílového počítače v bitech (32 nebo 64).

- `XBPS_TARGET_NO_ATOMIC8` Cílový počítač postrádá nativní 64bitové atomy (potřebuje emulaci libatomic).

- `XBPS_FETCH_CMD` Nástroj pro načítání souborů z `ftp` , `http` nebo `https` serverů.

- `XBPS_WRAPPERDIR` Úplná cesta k místu, kde jsou uloženy obaly xbps-src pro nástroje.

- `XBPS_CROSS_BASE` Úplná cesta k místu, kde jsou nainstalovány závislosti mezi kompilací, se liší podle cílového tripletu architektury. tj. `aarch64` -&gt; `/usr/aarch64-linux-gnu` .

- `XBPS_RUST_TARGET` Triplet cílové architektury používaný `rustc` a `cargo` .

- `XBPS_BUILD_ENVIRONMENT` Umožňuje operace specifické pro průběžnou integraci. Pokud se jedná o kontinuální integraci, nastavte na `void-packages-ci` .

<a id="available_vars"></a>

### Dostupné proměnné

<a id="mandatory_vars"></a>

#### Povinné proměnné

Seznam povinných proměnných pro šablonu:

- `homepage` URL odkazující na upstream domovskou stránku.

- <a id="var_license"></a> `license` A string matching the license's [SPDX Short identifier](https://spdx.org/licenses), `Public Domain`, or string prefixed with `custom:` for other licenses. Multiple licenses should be listed as an [SPDX license expression](https://spdx.github.io/spdx-spec/v3.0/annexes/SPDX-license-expressions/) (examples: `MIT OR Apache-2.0`, `MIT AND (LGPL-2.1-or-later OR BSD-3-Clause)`). Usage of `AND`, `OR`, `WITH`, and `()` are supported by xlint. The legacy comma-separated format should be converted when encountered (example: `GPL-3.0-or-later, custom:Hugware`).

    Prázdné metabalíčky, které neobsahují žádné soubory, a proto nemají a nevyžadují žádnou licenci, by měly používat `Public Domain` .

    Poznámka: `AGPL` , `MIT` , `BSD` , `ISC` , `X11` a vlastní licence vyžadují, aby byl licenční soubor dodán s binárním balíčkem.

- `maintainer` Řetězec ve tvaru `name <user@domain>` . E-mail pro toto pole musí být platný e-mail, na kterém vás lze zastihnout. Balíčky používající e-maily `users.noreply.github.com` nebudou přijímány.

- `pkgname` Řetězec s názvem balíčku, odpovídající `srcpkgs/<pkgname>` .

- `revision` Číslo, které musí být nastaveno na 1 při vytváření `source package` nebo aktualizováno na novou `upstream version` . Toto by mělo být zvýšeno pouze tehdy, když byly modifikovány generované `binary packages` .

- `short_desc` Řetězec se stručným popisem tohoto balíčku. Maximálně 72 znaků.

- `version` Řetězec s verzí balíčku. Nesmí obsahovat pomlčky ani podtržítko a je vyžadována alespoň jedna číslice. Použití substituce proměnné Shell není povoleno.

`pkgname` a `version` jsou zakázány obsahovat speciální znaky. Proto není nutné je citovat a podle konvence by ani neměly být.

<a id="optional_vars"></a>

#### Nepovinné proměnné

- `hostmakedepends` Seznam `host` závislostí potřebných k sestavení balíčku, který bude nainstalován do hlavního adresáře. Verzi není třeba zadávat, protože vždy bude vyžadována aktuální verze v srcpkgs. Příklad: `hostmakedepends="foo blah"` .

- `makedepends` Seznam `target` závislostí potřebných k sestavení balíčku, který bude nainstalován do hlavního adresáře. Verzi není třeba zadávat, protože vždy bude vyžadována aktuální verze v srcpkgs. Příklad: `makedepends="foo blah"` .

- `checkdepends` Seznam závislostí potřebných ke spuštění kontrol balíčků, tj. skriptu nebo pravidla make specifikovaného ve funkci `do_check()` šablony. Příklad: `checkdepends="gtest"` .

- `depends` Seznam závislostí potřebných ke spuštění balíčku. Tyto závislosti se neinstalují do hlavního adresáře, ale kontrolují se pouze v případě, že v místním úložišti existuje binární balíček, který vyhovuje požadované verzi. Závislosti lze specifikovat pomocí následujících komparátorů verzí: `<` , `>` , `<=` , `>=` nebo `foo-1.0_1` aby odpovídaly přesné verzi. Pokud není definován komparátor verzí (pouze název balíčku), je komparátor verzí automaticky nastaven na `>=0` . Příklad: `depends="foo blah>=1.0"` . Další informace naleznete v části [Závislosti běhového prostředí](#deps_runtime) .

- `bootstrap` Je-li povoleno, je zdrojový balíček považován za součást procesu `bootstrap` a vyžaduje se, aby bylo možné vytvářet balíčky v chrootu. Tuto vlastnost musí nastavit pouze malý počet balíčků.

- `conflicts` Volitelný seznam balíčků, které jsou v konfliktu s tímto balíčkem. Konflikty lze zadat pomocí následujících komparátorů verzí: `<` , `>` , `<=` , `>=` nebo `foo-1.0_1` aby odpovídaly přesné verzi. Pokud není definován komparátor verzí (pouze název balíčku), je komparátor verzí automaticky nastaven na `>=0` . Příklad: `conflicts="foo blah>=0.42.3"` .

- `distfiles` Úplná adresa URL pro `upstream` zdrojové distribuční soubory. Více souborů lze oddělit mezerami. Soubory musí končit `.tar.lzma` , `.tar.xz` , `.txz` , `.tar.bz2` , `.tbz` , `.tar.gz` , `.tgz` , `.gz` , `.bz2` , `.tar` nebo `.zip` . Chcete-li definovat cílový název souboru, připojte k adrese URL `>filename` . Příklad: distfiles="http://foo.org/foo-1.0.tar.gz http://foo.org/bar-1.0.tar.gz&gt;bar.tar.gz"

    Aby se předešlo opakování, existuje několik proměnných pro běžné hostitelské weby:

    Variabilní | Hodnota
    --- | ---
    CPAN_SITE | https://cpan.perl.org/modules/by-module
    DEBIAN_SITE | http://ftp.debian.org/debian/pool
    FREEDESKTOP_SITE | https://freedesktop.org/software
    GNOME_SITE | https://ftp.gnome.org/pub/GNOME/sources
    GNU_SITE | https://ftp.gnu.org/gnu
    KERNEL_SITE | https://www.kernel.org/pub/linux
    MOZILLA_SITE | https://ftp.mozilla.org/pub
    NONGNU_SITE | https://download.savannah.nongnu.org/releases
    PYPI_SITE | https://files.pythonhosted.org/packages/source
    SOURCEFORGE_SITE | https://downloads.sourceforge.net/sourceforge
    UBUNTU_SITE | http://archive.ubuntu.com/ubuntu/pool
    XORG_SITE | https://www.x.org/releases/individual
    KDE_SITE | https://download.kde.org/stable
    VIDEOLAN_SITE | https://download.videolan.org/pub/videolan

- `checksum` Digesty `sha256` odpovídající `${distfiles}` . Více souborů lze oddělit mezerami. Upozorňujeme, že objednávka musí být stejná, jako byla použita v `${distfiles}` . Příklad: `checksum="kkas00xjkjas"`

Pokud soubor distfile změní svůj kontrolní součet pro každé stažení, protože je zabalen za běhu na serveru, jako např. snapshot tarballs z libovolného z `https://*.googlesource.com/` webů, kontrolní součet `archive contents` lze určit pomocí předřazení reklamy na (@). U tarballů můžete najít kontrolní součet obsahu pomocí příkazu `tar xf <tarball.ext> --to-stdout | sha256sum` .

- `wrksrc` Název adresáře, do kterého jsou extrahovány zdroje balíčků, nastavený na `${pkgname}-${version}` .

- `build_wrksrc` Adresář související s `${wrksrc}` , který bude použit při sestavování balíčku.

- `create_wrksrc` Obvykle, po extrahování, pokud existuje více souborů a/nebo adresářů nejvyšší úrovně nebo pokud neexistují žádné adresáře, soubory a adresáře nejvyšší úrovně budou zabaleny do jedné další vrstvy adresáře. Chcete-li toto chování vynutit, nastavte `create_wrksrc` .

- `build_style` Určuje `build method` pro balíček. Přečtěte si níže, abyste se dozvěděli více o dostupných `build methods` balíčků nebo o efektu ponechání tohoto nenastaveného.

- `build_helper` mezerami oddělený seznam souborů v `common/build-helper` které mají být získávány a jeho proměnné zpřístupněny v šabloně. tj. `build_helper="rust"` .

- `configure_script` Název `configure` skriptu, který se má spustit ve fázi `configure` , pokud je `${build_style}` nastaveno na metody sestavení `configure` nebo `gnu-configure` . Standardně nastaveno na `./configure` .

- `configure_args` Argumenty, které mají být předány `configure` skriptu, pokud je `${build_style}` nastaveno na metody sestavení `configure` nebo `gnu-configure` . Ve výchozím nastavení musí být předpona nastavena na `/usr` . V balíčcích `gnu-configure` jsou některé volby již standardně nastaveny: `--prefix=/usr --sysconfdir=/etc --infodir=/usr/share/info --mandir=/usr/share/man --localstatedir=/var` .

- `make_cmd` Spustitelný soubor, který se spustí ve fázi `build` , pokud je `${build_style}` nastaveno na metody sestavení `configure` , `gnu-configure` nebo `gnu-makefile` . Standardně nastaveno na `make` .

- `make_build_args` Argumenty, které mají být předány do `${make_cmd}` ve fázi sestavování, pokud je `${build_style}` nastaveno na metody sestavení `configure` , `gnu-configure` nebo `gnu-makefile` . Ve výchozím nastavení zrušeno.

- `make_check_args` Argumenty, které mají být předány do `${make_cmd}` ve fázi kontroly, pokud je `${build_style}` nastaveno na metody sestavení `configure` , `gnu-configure` nebo `gnu-makefile` . Ve výchozím nastavení zrušeno.

- `make_install_args` Argumenty, které mají být předány do `${make_cmd}` ve fázi `install` , pokud je `${build_style}` nastaveno na metody sestavení `configure` , `gnu-configure` nebo `gnu-makefile` .

- `make_build_target` Cíl sestavení. Pokud je `${build_style}` nastaveno na `configure` , `gnu-configure` nebo `gnu-makefile` , toto je cíl předaný `${make_cmd}` ve fázi sestavení; když není nastaveno, použije se výchozí cíl. Pokud `${build_style}` je `python3-pep517` , toto je cesta k adresáři balíčku, který by měl být vytvořen jako Python wheel; pokud není nastaveno, výchozí hodnota je `.` (aktuální adresář s ohledem na sestavení).

- `make_check_target` Cíl, který má být předán do `${make_cmd}` ve fázi kontroly, pokud je `${build_style}` nastaveno na metody sestavení `configure` , `gnu-configure` nebo `gnu-makefile` . Ve výchozím nastavení je nastavena `check` .

- `make_install_target` Cíl instalace. Když je `${build_style}{/code1} nastaven na {code2}configure{/code2}, {code3}gnu-configure{/code3} nebo {code4}gnu-makefile{/code4}, toto je cíl předaný {code5}${make_command}` ve fázi instalace; pokud není nastaveno, ve výchozím nastavení se `install` . Pokud `${build_style}` je `python3-pep517`, jedná se o cestu pythonovského kola vytvořeného fází sestavení, která se nainstaluje; když není nastaveno, styl sestavení `python3-pep517` bude hledat wheel odpovídající názvu a verzi balíčku v aktuálním adresáři s ohledem na instalaci.

- `make_check_pre` Výraz před `${make_cmd}` . To lze použít pro příkazy wrapper nebo pro nastavení proměnných prostředí pro příkaz check. Ve výchozím nastavení prázdné.

- `patch_args` Argumenty, které mají být předány příkazu `patch(1)` při aplikaci oprav na zdroje balíčků během `do_patch()` . Opravy jsou uloženy ve `srcpkgs/<pkgname>/patches` a musí být ve formátu `-p1` . Standardně nastaveno na `-Np1` .

- `disable_parallel_build` Pokud je nastaveno, balíček nebude sestavován paralelně a `XBPS_MAKEJOBS` bude nastaven na 1. Pokud balíček nefunguje správně s `XBPS_MAKEJOBS` , ale stále má mechanismus pro paralelní sestavení, nastavte `disable_parallel_build` a použijte `XBPS_ORIG_MAKEJOBS` (který má původní hodnotu z `XBPS_MAKEJOBS` ) v šabloně.

- `disable_parallel_check` Pokud sady testů pro balíček nebudou sestaveny a spuštěny paralelně a `XBPS_MAKEJOBS` bude nastaveno na 1. Pokud balíček nefunguje dobře s `XBPS_MAKEJOBS` , ale stále má mechanismus pro paralelní spouštění kontrol, nastavte `disable_parallel_check` a použijte `XBPS_ORIG_MAKEJOBS` ( který má v šabloně původní hodnotu `XBPS_MAKEJOBS` ).

- `make_check` Nastavuje případy, ve kterých se spustí fáze `check` . Tato možnost musí být doplněna komentářem vysvětlujícím, proč testy selhávají. Povolené hodnoty:

    - `yes` (výchozí) ke spuštění, pokud je nastaveno `XBPS_CHECK_PKGS` .
    - `extended` na spuštění, pokud je `XBPS_CHECK_PKGS` `full` .
    - `ci-skip` se spustí lokálně, pokud je nastaveno `XBPS_CHECK_PKGS` , ale ne jako součást kontrol požadavku na stažení.
    - `no` nikdy neběhat.

- `keep_libtool_archives` Je-li povoleno, archivy `GNU Libtool` nebudou odstraněny. Ve výchozím nastavení jsou tyto soubory vždy automaticky odstraněny.

- `skip_extraction` Seznam názvů souborů, které by neměly být extrahovány ve fázi `extract` . Toto musí odpovídat základnímu názvu jakékoli adresy URL definované v `${distfiles}` . Příklad: `skip_extraction="foo-${version}.tar.gz"` .

- `nodebug` Pokud je povoleno, balíčky -dbg se nevygenerují, i když je nastaveno `XBPS_DEBUG_PKGS` .

- `conf_files` Seznam konfiguračních souborů, které binární balíček vlastní; to předpokládá úplné cesty, zástupné znaky budou rozšířeny a více položek může být odděleno mezerami. Příklad: `conf_files="/etc/foo.conf /etc/foo2.conf /etc/foo/*.conf"` .

- `mutable_files` Seznam souborů, které binární balíček vlastní, s očekáváním, že tyto soubory budou změněny. Ty se chovají hodně jako `conf_files` , ale bez předpokladu, že je bude upravovat člověk.

- `make_dirs` Seznam položek definujících adresáře a oprávnění, která mají být vytvořena při instalaci. Každý záznam by měl být oddělen mezerou a sám bude obsahovat mezery. `make_dirs="/dir 0750 user group"` . Uživatel, skupina a režim jsou vyžadovány na každém řádku, i když jsou `755 root root` . Podle konvence existuje pouze jeden záznam `dir perms user group` na řádek.

- `repository` Definuje úložiště, do kterého bude balíček umístěn. Seznam platných úložišť naleznete v *části Úložiště* .

- `nostrip` Pokud je nastaveno, binární soubory ELF se symboly ladění nebudou odstraněny. Ve výchozím nastavení jsou všechny binární soubory odstraněny.

- `nostrip_files` Seznam binárních souborů ELF oddělený mezerami, které nebudou zbaveny ladicích symbolů. Soubory mohou být zadány úplnou cestou nebo názvem souboru.

- `noshlibprovides` Je-li nastaveno, nebudou binární soubory ELF kontrolovány za účelem shromažďování poskytnutých sonames ve sdílených knihovnách.

- `noverifyrdeps` Pokud je nastaveno, binární soubory ELF a sdílené knihovny nebudou kontrolovány za účelem shromažďování jejich reverzních závislostí. Musíte zadat všechny závislosti v `depends` , když to potřebujete nastavit.

- `skiprdeps` Seznam názvů souborů oddělených mezerami určenými jejich absolutní cestou v `$DESTDIR` , které nebudou kontrolovány na závislosti za běhu. To může být užitečné pro přeskočení souborů, které nejsou určeny ke spuštění nebo načtení na hostiteli, ale mají být odeslány na nějaké cílové zařízení nebo emulaci.

- `ignore_elf_files` Seznam souborů strojového kódu v adresáři /usr/share zadaných absolutní cestou oddělených mezerami, které jsou očekávané a povolené.

- `ignore_elf_dirs` Bílými mezerami oddělený seznam adresářů v adresáři /usr/share specifikovaných absolutní cestou, které jsou očekávány a které mohou obsahovat soubory strojového kódu.

- `nocross` Je-li nastaveno, křížová kompilace nebude povolena a bude okamžitě ukončena. Toto by mělo být nastaveno na řetězec popisující, proč selže, nebo na odkaz na buildlog (od oficiálních tvůrců, CI buildlogy mohou zmizet) demonstrující selhání.

- `restricted` Pokud je nastaveno, xbps-src odmítne sestavit balíček, pokud `etc/conf` nemá `XBPS_ALLOW_RESTRICTED=yes` . Primární stavitelé pro Void Linux toto nastavení nemají, takže primární úložiště nebudou mít žádný omezený balíček. To je užitečné pro balíčky, kde licence zakazuje redistribuci.

- `subpackages` Seznam dílčích balíčků oddělených mezerami (odpovídající `foo_package()` ), aby se přepsal uhodnutý seznam. Toto použijte pouze v případě, že je vyžadováno specifické pořadí dílčích balíčků, jinak by ve většině případů fungovalo výchozí nastavení.

- `metapackage` Pokud je nastaveno na `yes` , balíček musí být prázdný metabalíček, tj. balíček, který závisí pouze na jiných balíčcích.

- `broken` Je-li nastaveno, sestavení balíčku nebude povoleno, protože jeho stav je aktuálně poškozen. Toto by mělo být nastaveno na řetězec popisující, proč je poškozený, nebo na odkaz na buildlog demonstrující selhání.

- `shlib_provides` Seznam dalších soname oddělených mezerami, na kterých balíček poskytuje. To se spíše připojí k vygenerovanému souboru než jej nahradí.

- `shlib_requires` Seznam dalších sonames, které balíček vyžaduje, oddělených mezerami. To se spíše připojí k vygenerovanému souboru než jej nahradí.

- `nopie` Pouze musí být nastaveno na něco, aby bylo aktivní, zakáže sestavení balíčku s funkcemi zpevnění (PIE, relro, atd.). U většiny balíčků to není nutné.

- `nopie_files` Seznam binárních souborů ELF oddělených mezerami, které nebudou kontrolovány na PIE. Soubory musí být zadány úplnou cestou.

- `reverts` xbps podporuje unikátní funkci, která umožňuje automatický downgrade z poškozených balíčků. V poli `reverts` lze definovat seznam poškozených pkgver, který by měl výsledný balíček vrátit. Toto pole *musí* být definováno před poli `version` a `revision` , aby fungovalo podle očekávání. Verze definované v `reverts` musí být větší než verze definovaná ve `version` . Příklad:

    ```
    reverts="2.0_1 2.0_2"
    version=1.9
    revision=2
    ```

- `alternatives` Seznam podporovaných alternativ, které balíček poskytuje, oddělený mezerami. Seznam se skládá ze tří složek oddělených dvojtečkou: skupina, symbolický odkaz a cíl. Příklad: `alternatives="vi:/usr/bin/vi:/usr/bin/nvi ex:/usr/bin/ex:/usr/bin/nvi-ex"` .

- `font_dirs` Seznam adresářů oddělených mezerami určený absolutní cestou, kam balíček písem instaluje svá písma. Používá se v `x11-fonts` xbps-trigger k opětovnému sestavení mezipaměti písem během instalace/odebírání balíčku. Příklad: `font_dirs="/usr/share/fonts/TTF /usr/share/fonts/X11/misc"`

- `dkms_modules` Seznam modulů Dynamic Kernel Module Support (dkms) oddělených mezerami, které budou nainstalovány a odstraněny `dkms` xbps-trigger s instalací/odstraněním balíčku. Formát je mezerou oddělený pár řetězců, které představují název modulu, většinou `pkgname` , a verzi modulu, většinou `version` . Příklad: `dkms_modules="$pkgname $version zfs 4.14"`

- `register_shell` Seznam shellů oddělených mezerami definovaný absolutní cestou, které mají být zaregistrovány do databáze systémových shellů. Používá ho spouštěč `register-shell` . Příklad: `register_shell="/bin/tcsh /bin/csh"`

- `tags` Seznam tagů (kategorií) oddělených mezerami, které jsou registrovány v metadatech balíčku a uživatelé je mohou dotazovat pomocí `xbps-query` . Příklad pro qutebrowser: `tags="browser chromium-based qt5 python3"`

- `perl_configure_dirs` Seznam oddělených prázdných míst ve vztahu k `wrksrc` , které obsahují soubory Makefile.PL, které musí být procesy, aby balík fungoval. Používá se v modulu build_style perl a mimo něj nemá žádné použití. Příklad: `perl_configure_dirs="blob/bob foo/blah"`

- `preserve` Je-li nastaveno, soubory vlastněné balíkem v systému nebudou při aktualizaci, přeinstalaci nebo odebrání balíku odstraněny. To je většinou užitečné pro balíčky jádra, které by neměly odstraňovat soubory jádra, když jsou odstraněny, pro případ, že by to mohlo přerušit zavádění uživatele a načítání modulů. Jinak by se ve většině případů neměl používat.

- `fetch_cmd` Spustitelný soubor, který se má použít k načtení URL v `distfiles` během fáze `do_fetch` .

- `changelog` URL odkazující na upstream changelog. Preferovány jsou soubory s nezpracovaným textem.

- `archs` Bílými znaky oddělený seznam architektur, pro které lze balíček sestavit, dostupné architektury lze nalézt pod `common/cross-profiles` . Obecně platí, že `archs` by měly být nastaveny pouze tehdy, pokud se upstream software výslovně zaměřuje na určité architektury nebo existuje pádný důvod, proč by software neměl být dostupný na některých podporovaných architekturách. Předřazení vzoru vlnovkou znamená zákaz stavět na naznačených obloucích. První odpovídající vzor se použije pro povolení/zakázání sestavení. Pokud neodpovídá žádný vzor, ​​balíček se sestaví, pokud poslední vzor obsahuje vlnovku. Příklady:

    ```
     # Build package only for musl architectures
     archs="*-musl"
     # Build package for x86_64-musl and any non-musl architecture
     archs="x86_64-musl ~*-musl"
     # Default value (all arches)
     archs="*"
    ```

Dříve byla k dispozici speciální hodnota `noarch` , ale od té doby byla odstraněna.

- `nocheckperms` Je-li nastaveno, xbps-src neselže při běžných chybách oprávnění (světové zapisovatelné soubory atd.)

- `nofixperms` Je-li nastaveno, xbps-src neopraví běžné chyby oprávnění (spustitelné manuálové stránky atd.)

- `no_generic_pkgconfig_link` Je-li nastaveno, xbps-src nevytvoří před vytvořením šablony symbolický odkaz z `$XBPS_CROSS_TRIPLET-pkg-config{/code1} na {code2}$XBPS_WRAPPERDIR/pkg-config`.

<a id="explain_depends"></a>

#### O mnoha typech `depends` proměnných

Doposud jsme uvedli čtyři typy `depends` proměnných: `hostmakedepends` , `makedepends` , `checkdepends` a `depends` . Tyto různé druhy proměnných jsou nezbytné, protože `xbps-src` podporuje křížovou kompilaci a aby se zabránilo instalaci zbytečných balíčků v prostředí sestavení.

Během procesu sestavení musí být na hostiteli *spuštěny* programy, jako je `yacc` nebo kompilátor C. Balíčky obsahující tyto programy by měly být uvedeny v `hostmakedepends` a budou nainstalovány na hostitele při sestavování cílového balíčku. Některé z těchto balíčků jsou závislé na balíčku `base-chroot` a nemusí být uvedeny. Je možné, že některé programy potřebné k sestavení projektu jsou umístěny v balíčcích `-devel` .

Cílový balíček může také záviset na jiných balíčcích pro knihovny, které se mají odkazovat na soubory záhlaví nebo na soubory záhlaví. Tyto balíčky by měly být uvedeny v `makedepends` a budou odpovídat cílové architektuře bez ohledu na architekturu sestavovacího stroje. Typicky budou `makedepends` obsahovat hlavně balíčky `-devel` .

Kromě toho, pokud je nastaveno `XBPS_CHECK_PKGS` nebo je předána volba `-Q` do `xbps-src` , může cílový balíček vyžadovat specifické závislosti nebo knihovny, které jsou propojeny s jeho testovacími binárními soubory, aby mohl spustit testovací sadu. Tyto závislosti by měly být uvedeny v `checkdepends` a budou nainstalovány, jako by byly součástí `hostmakedepends` . Některé závislosti, které lze zahrnout do `checkdepends` , jsou:

- `dejagnu` : používá se pro některé projekty GNU
- `cmocka-devel` : propojeno do testovacích binárních souborů
- `dbus` : umožňuje spouštět `dbus-run-session <test-command>` a poskytovat relaci D-Bus pro aplikace, které to potřebují
- `git` : některé testovací sady spouštějí příkaz `git`

<a id="deps_runtime"></a>A konečně, balíček může vyžadovat určité závislosti za běhu, bez kterých je nepoužitelný. Tyto závislosti, pokud je XBPS nezjistí automaticky, by měly být uvedeny v `depends` .

Knihovny propojené objekty ELF jsou detekovány automaticky pomocí `xbps-src` , proto je nelze specifikovat v šablonách pomocí `depends` . Tato proměnná by měla obsahovat:

- spustitelné soubory nazývané jako samostatné procesy.
- ELF objekty pomocí dlopen(3).
- neobjektový kód, např. hlavičky C, moduly perl/python/ruby/etc.
- datové soubory.
- přepíše minimální verzi uvedenou v souboru `common/shlibs` .

Závislosti běhu pro objekty ELF se zjišťují kontrolou, které SONAME vyžadují, a poté jsou SONAME mapovány na binární název balíčku s minimální požadovanou verzí. Soubor `common/shlibs` nastavuje mapování `<SONAME> <pkgname>>=<version>` .

Například balíček `foo-1.0_1` poskytuje `libfoo.so.1` SONAME a software vyžadující tuto knihovnu bude odkazovat na `libfoo.so.1` ; výsledný binární balíček bude mít závislost běhu na balíčku `foo>=1.0_1` jak je uvedeno v `common/shlibs` :

```
# common/shlibs
...
libfoo.so.1 foo-1.0_1
...
```

- První pole určuje SONAME.
- Ve druhém poli byl uveden název balíčku a minimální požadovaná verze.
- Třetí volitelné pole (obvykle nastavené na `ignore` ) lze použít k přeskočení kontrol v soname bumps.

Závislosti deklarované přes `depends` se neinstalují do hlavního adresáře, spíše se kontrolují, pokud existují jako binární balíčky, a jsou automaticky sestaveny `xbps-src` pokud zadaná verze není v lokálním úložišti.

Ve speciálním případě mohou být `virtual` závislosti specifikovány jako runtime závislosti v proměnné šablony `depends` . Několik různých balíčků může poskytovat běžnou funkcionalitu deklarováním virtuálního názvu a verze v proměnné šablony `provides` (např `provides="vpkg-0.1_1"` ). Balíčky, které se spoléhají na společnou funkčnost bez ohledu na konkrétního poskytovatele, mohou deklarovat závislost na názvu virtuálního balíčku s předponou `virtual?` (např. `depends="virtual?vpkg-0.1_1"` ). Když je balíček sestaven pomocí `xbps-src` , bude potvrzena existence poskytovatelů virtuálních balíčků a budou sestaveni v případě potřeby. Mapa z virtuálních balíčků na jejich výchozí poskytovatele je definována v `etc/defaults.virtual` . Jednotlivá mapování mohou být přepsána místními preferencemi v `etc/virtual` . Komentáře v `etc/defaults.virtual` poskytují více informací o této mapě.

A konečně, obecně platí, že pokud je balíček sestavován přesně stejným způsobem bez ohledu na to, zda je konkrétní balíček přítomen v `makedepends` nebo `hostmakedepends` , neměl by být tento balíček přidán jako závislost na čase sestavení.

<a id="repositories"></a>

### Úložiště

<a id="repo_by_branch"></a>

#### Repozitáře definované větví

Globální úložiště převezme název aktuální větve, kromě případů, kdy je název větve hlavní. Potom bude výsledné úložiště v globálním rozsahu. Scénář použití je takový, že uživatel může aktualizovat více balíčků v druhé větvi, aniž by znečišťoval své místní úložiště.

<a id="pkg_defined_repo"></a>

#### Repozitáře definované balíčkem

Druhým způsobem, jak definovat úložiště, je nastavení proměnné `repository` v šabloně. Tímto způsobem může správce definovat úložiště pro konkrétní balíček nebo skupinu balíčků. To se v současnosti používá k rozlišení mezi určitými třídami balíčků.

Následující názvy úložišť jsou platné:

- `bootstrap` : Úložiště pro balíčky specifické pro xbps-src.
- `debug` : Úložiště pro balíčky obsahující ladicí symboly. Téměř ve všech případech jsou tyto balíčky generovány automaticky.
- `nonfree` : Úložiště pro balíčky, které jsou uzavřeným zdrojem nebo mají nesvobodné licence.

<a id="updates"></a>

### Kontrola nových upstream vydání

Nové upstream verze mohou být automaticky kontrolovány pomocí `./xbps-src update-check <pkgname>` . V některých případech je potřeba přepsat rozumné výchozí hodnoty přiřazením následujících proměnných v `update` souboru ve stejném adresáři jako příslušný soubor `template` :

- `site` obsahuje URL, kde je uvedeno číslo verze. Pokud není nastaveno, jako výchozí se použije `homepage` a adresáře, kde jsou uloženy `distfiles` .

- `pkgname` je název balíčku, který výchozí vzor kontroluje. Není-li nastaveno, použije se výchozí `pkgname` ze šablony.

- `pattern` je regulární výraz kompatibilní s perl, který odpovídá číslu verze. Ukotvěte číslo verze pomocí `\K` a `(?=...)` . Příklad: `pattern='<b>\K[\d.]+(?=</b>)'` , toto odpovídá číslu verze uzavřenému ve značkách `<b>...</b>` .

- `ignore` je mezerami oddělený seznam shellů, které odpovídají číslům verzí, které nejsou brány v úvahu při kontrole novějších verzí. Příklad: `ignore="*b*"`

- `version` je číslo verze používané k porovnání s upstream verzemi. Příklad: `version=${version//./_}`

- `single_directory` lze nastavit tak, aby zakázalo zjišťování adresáře obsahujícího jednu verzi zdrojů v url a následné hledání nové verze v sousedních adresářích.

- `vdprefix` je perl kompatibilní regulární výraz odpovídající část, která předchází číselné části adresáře verze v url. Výchozí hodnota je `(|v|$pkgname)[-_.]*` .

- `vdsuffix` je perl kompatibilní regulární výraz odpovídající část, která následuje číselnou část adresáře verze v url. Výchozí hodnota je `(|\.x)` .

- `disabled` lze nastavit pro zakázání kontroly aktualizací pro balíček v případech, kdy kontrola aktualizací není možná nebo nedává smysl. Toto by mělo být nastaveno na řetězec popisující, proč je zakázáno.

<a id="patches"></a>

### Manipulace s náplastmi

Někdy je potřeba software opravit, nejčastěji k opravě nalezených chyb nebo k opravě kompilace s novým softwarem.

Pro řešení tohoto problému má xbps-src funkci záplatování. Vyhledá všechny soubory, které odpovídají globu `srcpkgs/$pkgname/patches/*.{diff,patch}` a automaticky použije všechny soubory, které najde pomocí `patch(1)` s `-Np1` . To se děje během fáze `do_patch()` . Proměnná `PATCHESDIR` je k dispozici v šabloně a ukazuje na adresář `patches` .

Chování záplatování lze změnit následujícími způsoby:

- V adresáři `patches` lze vytvořit soubor nazvaný `series` se seznamem oprav odděleným novým řádkem, které se mají aplikovat v uvedeném pořadí. Pokud je přítomen xbps-src, použije pouze záplaty uvedené v souboru `series` .

- Soubor se stejným názvem jako jeden z patchů, ale s příponou `.args` lze použít k nastavení arg předávaných `patch(1)` . Pokud například `foo.patch` vyžaduje předání speciálních argumentů do `patch(1)` , které nelze použít při aplikaci jiných patchů, lze vytvořit `foo.patch.args` obsahující tyto argumenty.

<a id="build_scripts"></a>

### vytvářet stylové skripty

Proměnná `build_style` určuje metodu sestavení pro sestavení a instalaci balíčku. Očekává název libovolného dostupného skriptu v adresáři `void-packages/common/build-style` . Vezměte prosím na vědomí, že požadované balíčky pro spuštění skriptu `build_style` musí být definovány pomocí `$hostmakedepends` .

Aktuální seznam dostupných skriptů `build_style` je následující:

- Pokud `build_style` není nastaven, šablona musí (alespoň) definovat funkci `do_install()` a volitelně více fází sestavení, jako je `do_configure()` , `do_build()` atd., a může přepsat výchozí `do_fetch()` a `do_extract()` , které načítají a extrahovat soubory definované v proměnné `distfiles` .

- `cargo` Pro balíky napsané v rzi, které používají Cargo pro stavbu. Konfigurační argumenty (jako je `--features` ) lze definovat v proměnné `configure_args` a jsou předány do cargo během `do_build` .

- `cmake` U balíčků, které používají systém sestavení CMake, lze konfigurační argumenty předávat pomocí `configure_args` . Proměnná `cmake_builddir` může být definována tak, aby specifikovala adresář pro sestavení pod `build_wrksrc` namísto výchozího `build` .

- `configure` U balíčků, které používají konfigurační skripty jiné než GNU, by mělo být předáno alespoň `--prefix=/usr` prostřednictvím `configure_args` .

- `fetch` Pro balíčky, které pouze načítají soubory a instalují se tak, jak jsou, pomocí `do_install()` .

- `gnu-configure` Pro balíčky, které používají konfigurační skripty kompatibilní s GNU autotools, lze další konfigurační argumenty předat pomocí `configure_args` .

- `gnu-makefile` U balíčků, které používají GNU make, lze argumenty buildu předat pomocí `make_build_args` a argumenty instalace pomocí `make_install_args` . Cíl sestavení lze přepsat pomocí `make_build_target` a cíl instalace pomocí `make_install_target` . Tento styl sestavování se snaží kompenzovat makefily, které nerespektují proměnné prostředí, takže dobře napsané makefily, ty, které dělají takové věci, jako je připojení ( `+=` ) k proměnným, by měly mít v těle šablony nastaveno `make_use_env` .

- `go` Pro programy napsané v Go, které se řídí standardní strukturou balíčků. Proměnná `go_import_path` musí být nastavena na cestu importu balíčku, např. `github.com/github/hub` pro program `hub` . Tyto informace lze nalézt v souboru `go.mod` pro moderní projekty Go. Očekává se, že distfile obsahuje balíček, ale závislosti budou staženy pomocí `go get` .

- `R-cran` Pro balíčky, které jsou dostupné v The Comprehensive R Archive Network (CRAN). Styl sestavení vyžaduje, aby `pkgname` začínal `R-cran-` a všechny pomlčky ( `-` ) ve verzi dané CRAN byly nahrazeny znakem `r` v proměnné `version` . Umístění `distfiles` bude automaticky nastaveno a balíček bude závislý na `R` .

- `gemspec` Pro balíčky, které používají soubory [gemspec](https://guides.rubygems.org/specification-reference/) pro vytvoření rubínového drahokamu a jeho následnou instalaci. Příkaz gem lze přepsat příkazem `gem_cmd` . `configure_args` lze použít k předání argumentů během kompilace. Pokud váš balíček nepoužívá zkompilovaná rozšíření, zvažte použití stylu sestavení `gem` .

- `gem` Pro balíčky, které se instalují pomocí drahokamů od [RubyGems](https://rubygems.org/) . Příkaz gem lze přepsat příkazem `gem_cmd` . `distfiles` je nastaven stylem sestavení, pokud tak šablona nečiní. Pokud váš drahokam poskytuje rozšíření, která musí být zkompilována, zvažte použití stylu sestavení `gemspec` .

- `ruby-module` Pro balíčky, které jsou moduly ruby ​​a lze je nainstalovat přes `ruby install.rb` . Další argumenty instalace lze zadat pomocí `make_install_args` .

- `perl-ModuleBuild` Pro balíčky, které používají metodu Perl [Module::Build](https://metacpan.org/pod/Module::Build) .

- `perl-module` Pro balíčky, které používají metodu sestavení Perl [ExtUtils::MakeMaker](http://perldoc.perl.org/ExtUtils/MakeMaker.html) .

- `raku-dist` Pro balíčky, které používají metodu sestavení Raku `raku-install-dist` s rakudo.

- `waf3` Pro balíčky, které používají Python3 metodu sestavení `waf` s python3.

- `slashpackage` Pro balíčky, které k sestavení používají hierarchii /package a package/compile, jako je například `daemontools` nebo jakýkoli `djb` software.

- `qmake` U balíčků, které používají profily Qt5/Qt6 qmake ( `*.pro` ), mohou být argumenty qmake pro fázi configure předány prostřednictvím `configure_args` , argumenty make build mohou být předány pomocí `make_build_args` a argumenty instalace pomocí `make_install_args` . Cíl sestavení lze přepsat pomocí `make_build_target` a cíl instalace pomocí `make_install_target` .

- `meson` U balíčků, které používají systém Meson Build, lze konfigurační volby předat přes `configure_args` , příkaz meson lze přepsat pomocí `meson_cmd` a umístění out of source buildu pomocí `meson_builddir`

- `void-cross` Pro cross-toolchain balíčky používané k budování Void systémů. Neexistují žádné povinné proměnné (cílový triplet je odvozen), ale můžete zadat některé volitelné - `cross_gcc_skip_go` lze zadat pro přeskočení `gccgo` , jednotlivé argumenty konfigurace podprojektu lze zadat pomocí `cross_*_configure_args` kde `*` je `binutils` , `gcc_bootstrap` (předčasné gcc), `gcc` (final gcc), `glibc` (nebo `musl` ), `configure_args` je navíc předán jak ranému, tak konečnému `gcc` . Můžete také zadat vlastní `CFLAGS` a `LDFLAGS` pro knihovnu libc jako `cross_(glibc|musl)_(cflags|ldflags)` .

- `zig-build` Pro balíčky používající systém sestavení [Zig](https://ziglang.org) . Další argumenty lze předat vyvolání `zig build` pomocí `configure_args` .

U balíčků, které používají metodu sestavení modulu Python ( `setup.py` nebo [PEP 517](https://www.python.org/dev/peps/pep-0517/) ), si můžete vybrat jednu z následujících možností:

- `python3-module` pro sestavení modulů Pythonu 3.x

- `python3-pep517` k sestavení modulů Pythonu 3.x, které poskytují popis sestavení PEP 517 bez skriptu `setup.py`

Proměnné prostředí pro konkrétní `build_style` lze deklarovat v názvu souboru, který odpovídá názvu `build_style` , Příklad:

```
`common/environment/build-style/gnu-configure.sh`
```

- `texmf` Pro texmf zip/tarballs, které potřebují jít do /usr/share/texmf-dist. Zahrnuje manipulaci s duplikáty.

<a id="build_helper"></a>

### vytvářet pomocné skripty

Proměnná `build_helper` specifikuje úryvky shellu, které mají být získávány a které vytvoří vhodné prostředí pro práci s určitými sadami balíčků.

Aktuální seznam dostupných skriptů `build_helper` je následující:

- `cmake-wxWidgets-gtk3` nastavuje proměnnou `WX_CONFIG` , kterou používá FindwxWidgets.cmake

- `gir` specifikuje závislosti pro nativní a křížová sestavení pro řešení GObject Introspection. Následující proměnné lze nastavit v šabloně pro zpracování křížových sestavení, která vyžadují další nápovědu nebo vykazují problémy. `GIR_EXTRA_LIBS_PATH` definuje další cesty, které se mají prohledávat při propojování cílových binárních souborů, které mají být introspekovány. `GIR_EXTRA_OPTIONS` definuje další možnosti pro `g-ir-scanner-qemuwrapper` volající `qemu-<target_arch>-static` při spuštění cílového binárního souboru. Můžete například zadat `GIR_EXTRA_OPTIONS="-strace"` abyste viděli stopu toho, co se stane při spuštění této binárky.

- `meson` vytvoří křížový soubor `${XBPS_WRAPPERDIR}/meson/xbps_meson.cross` , který nakonfiguruje meson pro křížové sestavení. To je zvláště užitečné pro sestavování balíčků, které zalamují vyvolání mesonu (např. balíčky `python3-pep517` , které používají backend meson) a přidává se standardně pro balíčky, které používají styl sestavení `meson` .

- `numpy` konfiguruje prostředí pro křížovou kompilaci pythonových balíčků, které poskytují kompilovaná rozšíření odkazující na knihovny NumPy C. Pokud je také nakonfigurován pomocník sestavení `meson` , zapíše se sekundární křížový soubor `${XBPS_WRAPPERDIR}/meson/xbps_numpy.cross` , aby informoval meson, kde lze nalézt běžné komponenty NumPy.

- `python3` konfiguruje prostředí cross-build tak, aby používala knihovny Pythonu, hlavičkové soubory a konfigurace interpretů v cílovém kořenovém adresáři. Pomocník `python3` je standardně přidán pro balíčky, které používají styly sestavení `python3-module` nebo `python3-pep517` .

- `qemu` nastavuje další proměnné pro styly sestavení `cmake` a `meson` , aby bylo možné spouštět křížově kompilované binární soubory uvnitř qemu. Nastaví `CMAKE_CROSSCOMPILING_EMULATOR` pro cmake a `exe_wrapper` pro meson na `qemu-<target_arch>-static` a `QEMU_LD_PREFIX` na `XBPS_CROSS_BASE` . Vytvoří také funkci `vtargetrun` pro zabalení příkazů do volání `qemu-<target_arch>-static` pro cílovou architekturu.

- `qmake` vytvoří konfigurační soubor `qt.conf` (srov. `qmake` `build_style` ) potřebný pro křížová sestavení a qmake-wrapper, aby `qmake` použil tuto konfiguraci. Cílem je opravit křížová sestavení pro případ, že je styl sestavení smíšený: např. když ve stylu `gnu-configure` konfigurační skript volá `qmake` nebo `Makefile` ve stylu `gnu-makefile` . Toto je pro balíčky Qt5.

- `qmake6` is like `qmake` but for Qt6.

- `rust` specifikuje proměnné prostředí požadované pro křížovou kompilaci přepravek přes náklad a pro kompilaci cargo -sys přepravek. Přidává také obalovač `cargo` , který detekuje a prochází sestavami `cargo-auditable` . Tento pomocník je standardně přidán pro balíčky, které používají styl sestavení `cargo` .

- `haskell` specifikuje proměnné prostředí pro cabal. Tato pomocná funkce je standardně přidána pro balíčky, které používají styl sestavení `haskell-stack` nebo `cabal` .

<a id="functions"></a>

### Funkce

Následující funkce mohou být definovány pro změnu chování, jak se balíček stahuje, kompiluje a instaluje.

- `pre_fetch()` Akce, které se mají provést před `do_fetch()` .

- `do_fetch()` pokud je definováno a není nastaveno `distfiles` , použijte jej k načtení požadovaných zdrojů.

- `post_fetch()` Akce, které se mají provést po `do_fetch()` .

- `pre_extract()` Akce, které se mají provést po `post_fetch()` .

- `do_extract()` pokud je definováno a není nastaveno `distfiles` , použijte jej k extrahování požadovaných zdrojů.

- `post_extract()` Akce, které se mají provést po `do_extract()` .

- `pre_patch()` Akce, které se mají provést po `post_extract()` .

- `do_patch()` pokud je definována, použijte ji k přípravě prostředí pro sestavení a spuštění háčků pro aplikaci záplat.

- `post_patch()` Akce, které se mají provést po `do_patch()` .

- `pre_configure()` Akce, které se mají provést po `post_patch()` .

- `do_configure()` Akce pro provedení konfigurace balíčku; `${configure_args}` by měl být stále předán, pokud se jedná o konfigurační skript GNU.

- `post_configure()` Akce, které se mají provést po `do_configure()` .

- `pre_build()` Akce, které se mají provést po `post_configure()` .

- `do_build()` Akce k provedení sestavení balíčku.

- `post_build()` Akce, které se mají provést po `do_build()` .

- `pre_check()` Akce, které se mají provést po `post_build()` .

- `do_check()` Akce, které se mají provést pro spuštění kontroly balíčku.

- `post_check()` Akce, které se mají provést po `do_check()` .

- `pre_install()` Akce, které se mají provést po `post_check()` .

- `do_install()` Akce, které se mají provést k instalaci souborů balíčku do `fake destdir` .

- `post_install()` Akce, které se mají provést po `do_install()` .

- `do_clean()` Akce, které se mají provést pro vyčištění po úspěšné fázi balíčku.

> Funkce definovaná v šabloně má přednost před stejnou funkcí definovanou skriptem `build_style` .

Aktuální pracovní adresář pro funkce je nastaven takto:

- Pro pre_fetch, pre_extract, do_clean: `<masterdir>` .

- Pro do_fetch, post_fetch: `XBPS_BUILDDIR` .

- Pro do_extract přes do_patch: `wrksrc` .

- Pro post_patch až post_install: `build_wrksrc` pokud je definován, jinak `wrksrc` .

<a id="build_options"></a>

### Možnosti sestavení

Některé balíčky mohou být sestaveny s různými možnostmi sestavení, aby bylo možné povolit/zakázat další funkce; Kolekce zdrojových balíčků XBPS vám to umožňuje pomocí několika jednoduchých úprav souboru `template` .

Následující proměnné mohou být nastaveny tak, aby umožňovaly možnosti sestavení balíčku:

- `build_options` Nastavuje možnosti sestavení podporované zdrojovým balíčkem.

- `build_options_default` Nastavuje výchozí možnosti sestavení, které má použít zdrojový balíček.

- `desc_option_<option>` Nastaví popis pro `option` volby sestavení . To se musí shodovat s klíčovým slovem nastaveným v *build_options* . Všimněte si, že pokud je možnost sestavení dostatečně obecná, její popis by měl být místo toho přidán do `common/options.description` .

Po definování těchto požadovaných proměnných můžete zkontrolovat proměnnou `build_option_<option>` , abyste věděli, zda byla nastavena, a podle toho upravit zdrojový balíček. Kromě toho jsou k dispozici následující funkce:

- *vopt_if()* `vopt_if <option> <if_true> [<if_false>]`

    Výstup `if_true` pokud je nastavena `option` , nebo `if_false` pokud není nastavena.

- *vopt_with()* `vopt_with <option> [<flag>]`

    Výstup `--with-<flag>` , pokud je tato možnost nastavena, nebo `--without-<flag>` v opačném případě. Není-li `flag` nastaven, výchozí je `option` .

    Příklady:

    - `vopt_with dbus`
    - `vopt_with xml xml2`

- *vopt_enable()* `vopt_enable <option> [<flag>]`

    Stejné jako `vopt_with` , ale používá `--enable-<flag>` a `--disable-<flag>` .

- *vopt_conflict()* `vopt_conflict <option 1> <option 2>`

    Vydá chybu a ukončí se, pokud jsou obě možnosti nastaveny současně.

- *vopt_bool()* `vopt_bool <option> <property>`

    Výstupy `-D<property>=true` pokud je volba nastavena, nebo `-D<property>=false` v opačném případě.

- *vopt_feature()* `vopt_feature <option> <property>`

    Stejné jako `vopt_bool` , ale používá `-D<property>=enabled` a `-D<property>=disabled` .

Následující příklad ukazuje, jak změnit zdrojový balíček, který používá konfiguraci GNU, aby povolil novou možnost sestavení pro podporu obrázků PNG:

```
# Template file for 'foo'
pkgname=foo
version=1.0
revision=1
build_style=gnu-configure
configure_args="... $(vopt_with png)"
makedepends="... $(vopt_if png libpng-devel)"
...

# Package build options
build_options="png"
desc_option_png="Enable support for PNG images"

# To build the package by default with the `png` option:
#
# build_options_default="png"

...

```

Podporované možnosti sestavení pro zdrojový balíček lze zobrazit pomocí `xbps-src` :

```
$ ./xbps-src show-options foo
```

Možnosti sestavení lze povolit pomocí parametru `-o` `xbps-src` :

```
$ ./xbps-src -o option,option1 <cmd> foo
```

Možnosti sestavení lze zakázat jejich přidáním předponu `~` :

```
$ ./xbps-src -o ~option,~option1 <cmd> foo
```

Oba způsoby lze použít společně k povolení a/nebo zakázání více možností současně s `xbps-src` :

```
$ ./xbps-src -o option,~option1,~option2 <cmd> foo
```

Možnosti sestavení lze také zobrazit pro binární balíčky pomocí `xbps-query(8)` :

```
$ xbps-query -R --property=build-options foo
```

Trvalé globální možnosti sestavení balíčku lze nastavit pomocí proměnné `XBPS_PKG_OPTIONS` v konfiguračním souboru `etc/conf` . Možnosti sestavení pro jednotlivé balíčky lze nastavit pomocí `XBPS_PKG_OPTIONS_<pkgname>` .

> POZNÁMKA: Pokud `pkgname` obsahuje `dashes` , měly by být nahrazeny `underscores` Příklad: `XBPS_PKG_OPTIONS_xorg_server=opt` .

Seznam podporovaných voleb sestavení balíčku a jeho popis je definován v souboru `common/options.description` .

<a id="install_remove_files"></a>

### INSTALOVAT a ODEBRAT soubory

Útržky shellu INSTALL a REMOVE lze použít k provedení určitých akcí v určené fázi, když je binární balíček instalován, aktualizován nebo odstraněn. Existují některé proměnné, které jsou vždy nastaveny `xbps` při provádění skriptů:

- `$ACTION` : pro podmínění jeho akcí: `pre` nebo `post` .
- `$PKGNAME` : název balíčku.
- `$VERSION` : verze balíčku.
- `$UPDATE` : nastavte na `yes` pokud se balíček aktualizuje, `no` , pokud se balíček `installed` nebo `removed` .
- `$CONF_FILE` : úplná cesta k `xbps.conf` .
- `$ARCH` : cílová architektura, na které běží.

Příklad toho, jak má být vytvořen skript `INSTALL` nebo `REMOVE` , je uveden níže:

```
# INSTALL
case "$ACTION" in
pre)
	# Actions to execute before the package files are unpacked.
	...
	;;
post)
	if [ "$UPDATE" = "yes" ]; then
		# actions to execute if package is being updated.
		...
	else
		# actions to execute if package is being installed.
		...
	fi
	;;
esac
```

dílčí balíčky mohou mít také své vlastní soubory `INSTALL` a `REMOVE` , jednoduše je vytvořte jako `srcpkgs/<pkgname>/<subpkg>.INSTALL` nebo `srcpkgs/<pkgname>/<subpkg>.REMOVE` .

> POZNÁMKA: Vždy používejte cesty relativně k aktuálnímu pracovnímu adresáři, jinak pokud skripty nelze spustit přes `chroot(2)` nebudou správně fungovat.

> POZNÁMKA: K tisku zpráv nepoužívejte skripty INSTALL/REMOVE, další informace naleznete v další části.

<a id="install_remove_files_msg"></a>

### INSTALL.msg a REMOVE.msg soubory

Soubory `INSTALL.msg` a `REMOVE.msg` lze použít k vytištění zprávy v době po instalaci nebo před odstraněním.

V ideálním případě by tyto soubory neměly přesáhnout 80 znaků na řádek.

dílčí balíčky mohou mít také své vlastní soubory `INSTALL.msg` a `REMOVE.msg` , jednoduše je vytvořte jako `srcpkgs/<pkgname>/<subpkg>.INSTALL.msg` nebo `srcpkgs/<pkgname>/<subpkg>.REMOVE.msg` .

Toto by se mělo používat pouze pro kritické zprávy, jako je varování uživatelů o porušení změn.

<a id="runtime_account_creation"></a>

### Vytváření systémových účtů/skupin za běhu

Existuje spouštěč spolu s některými proměnnými, které jsou specificky určeny k vytvoření **systémových uživatelů a skupin** při konfiguraci binárního balíčku. K tomuto účelu lze použít následující proměnné:

- `system_groups` Určuje názvy nových *skupin systémů* , které mají být vytvořeny, oddělené mezerami. Volitelně lze zadat **gid** oddělením dvojtečkou, tj. `system_groups="_mygroup:78"` nebo `system_groups="_foo _blah:8000"` .

- `system_accounts` Určuje jména nových **systémových uživatelů/skupin,** které mají být vytvořeny, oddělená mezerami, tj `system_accounts="_foo _blah:22"` . Volitelně lze **uid** a **gid** specifikovat jejich oddělením dvojtečkou, tj. `system_accounts="_foo:48"` . Pro změnu chování **systémových účtů** lze zadat další proměnné:

    - `<account>_homedir` domovský adresář uživatele. Pokud není nastaveno, výchozí je `/var/empty` .
    - `<account>_shell` shell pro nového uživatele. Pokud není nastaveno, výchozí je `/sbin/nologin` .
    - `<account>_descr` popis pro nového uživatele. Pokud není nastaveno, výchozí je `<account> unprivileged user` .
    - `<account>_groups` další skupiny, které mají být přidány pro nového uživatele.
    - `<account>_pgroup` pro nastavení primární skupiny, ve výchozím nastavení je primární skupina nastavena na `<account>` .

**Systémový uživatel** je vytvořen pomocí dynamicky přiděleného **uid/gid** ve vašem systému a je vytvořen jako `system account` , pokud není nastaveno **uid** . Pro zadaný `system account` bude vytvořena nová skupina a bude použita výhradně pro tento účel.

Systémové účty a skupiny musí mít předponu podtržítka, aby se předešlo střetu s názvy uživatelských účtů.

> POZNÁMKA: Zásady podtržení se nevztahují na staré balíčky, kvůli nevyhnutelnému porušení změny uživatelského jména by se podle něj měly řídit pouze nové balíčky.

<a id="writing_runit_services"></a>

### Psaní runitových služeb

Void Linux používá [runit](http://smarden.org/runit/) pro bootování a dohled nad službami.

Většinu informací o tom, jak je napsat, najdete v jejich [FAQ](http://smarden.org/runit/faq.html#create) . Následují pokyny specifické pro Void Linux, jak psát služby.

Pokud démon služby podporuje příznaky CLI, zvažte přidání podpory pro jeho změnu prostřednictvím proměnné `OPTS` čtením souboru s názvem `conf` ve stejném adresáři jako démon.

```sh
#!/bin/sh
[ -r conf ] && . ./conf
exec daemon ${OPTS:- --flag-enabled-by-default}
```

Pokud služba vyžaduje vytvoření adresáře pod `/run` nebo jeho odkazu `/var/run` pro ukládání runtime informací (jako Pidfiles), zapište jej do souboru služby. Pokud jej potřebujete vytvořit se specifickými oprávněními, doporučujeme použít `install` namísto `mkdir -p` .

```sh
#!/bin/sh
install -d -m0700 /run/foo
exec foo
```

```sh
#!/bin/sh
install -d -m0700 -o bar -g bar /run/bar
exec bar
```

Pokud služba vyžaduje adresáře v částech systému, které obecně nejsou v dočasných souborových systémech. Poté použijte proměnnou `make_dirs` v šabloně k vytvoření těchto adresářů, když je balíček nainstalován.

Pokud balíček nainstaluje servisní soubor systemd nebo jinou jednotku, ponechte jej na místě jako referenční bod, pokud jeho zahrnutí nemá žádné negativní vedlejší účinky.

Příklady, kdy *neinstalovat* systémové jednotky:

1. Když tak učiníte, změní se běhové chování přibaleného softwaru.
2. Když se to provádí pomocí příznaku doby kompilace, který také mění závislosti sestavení.

<a id="32bit_pkgs"></a>

### 32bitové balíčky

32bitové balíčky se sestavují automaticky, když je tvůrce x86 (32bit), ale existují některé proměnné, které mohou chování změnit:

- `lib32depends` Je-li tato proměnná nastavena, budou zde uvedené závislosti použity spíše než závislosti detekované automaticky `xbps-src` a **závisí** . Vezměte prosím na vědomí, že závislosti musí být specifikovány pomocí komparátorů verzí, Příklad: `lib32depends="foo>=0 blah<2.0"` .

- `lib32disabled` Pokud je tato proměnná nastavena, nebude sestaven žádný 32bitový balíček.

- `lib32files` Další soubory, které mají být přidány do **32bitového** balíčku. To očekává absolutní cesty oddělené mezerami, Příklad: `lib32files="/usr/bin/blah /usr/include/blah."` .

- `lib32symlinks` Vytvoří symbolický odkaz cílového souboru uloženého v adresáři `lib32` . To očekává základní název cílového souboru, Příklad: `lib32symlinks="foo"` .

- `lib32mode` Pokud není nastaveno, do **32bitového** balíčku budou zkopírovány pouze sdílené/statické knihovny a soubory pkg-config. Pokud je nastaveno na `full` všechny soubory budou zkopírovány do 32bitového balíčku, nezměněné.

<a id="pkgs_sub"></a>

### Dílčí balíčky

Ve výše uvedeném příkladu se vygeneruje pouze binární balíček, ale pomocí některých jednoduchých vylepšení lze z jedné šablony/sestavení vygenerovat více binárních balíčků, tomu se říká `subpackages` .

Chcete-li vytvořit další `subpackages` musí `template` definovat novou funkci s tímto názvem: `<subpkgname>_package()` , Příklad:

```
# Template file for 'foo'
pkgname=foo
version=1.0
revision=1
build_style=gnu-configure
short_desc="A short description max 72 chars"
maintainer="name <email>"
license="GPL-3.0-or-later"
homepage="http://www.foo.org"
distfiles="http://www.foo.org/foo-${version}.tar.gz"
checksum="fea0a94d4b605894f3e2d5572e3f96e4413bcad3a085aae7367c2cf07908b2ff"

# foo-devel is a subpkg
foo-devel_package() {
	short_desc+=" - development files"
	depends="${sourcepkg}>=${version}_${revision}"
	pkg_install() {
		vmove usr/include
		vmove "usr/lib/*.a"
		vmove "usr/lib/*.so"
		vmove usr/lib/pkgconfig
	}
}
```

Všechny dílčí balíčky potřebují další symbolický odkaz na `main` balíček, jinak závislosti vyžadující tyto balíčky nenajdou svou `template` Příklad:

```
 /srcpkgs
  |- foo <- directory (main pkg)
  |  |- template
  |- foo-devel <- symlink to `foo`
```

Hlavní balíček by měl specifikovat všechny požadované `build dependencies` , aby bylo možné sestavit všechny dílčí balíčky definované v šabloně.

Důležitým bodem `subpackages` je, že jsou zpracovány poté, co hlavní balíček dokončil svou fázi `install` . Funkce `pkg_install()` na nich specifikovaná se běžně používá k přesunu souborů z `main` balíčku destdir do `subpackage` destdir.

Pomocné funkce `vinstall` , `vmkdir` , `vcopy` a `vmove` jsou jen obaly, které zjednodušují proces vytváření, kopírování a přesouvání souborů/adresářů mezi `main` balíčkem destdir ( `$DESTDIR` ) do `subpackage` destdir ( `$PKGDESTDIR` ).

Dílčí balíčky jsou zpracovávány vždy v abecedním pořadí; Chcete-li vynutit vlastní objednávku, lze proměnnou `subpackages` deklarovat s požadovanou objednávkou.

<a id="pkgs_classes"></a>

### Některé třídy balíčků

<a id="pkgs_development"></a>

#### Vývojové balíčky

Vývojový balíček, běžně generovaný jako dílčí balíček, bude obsahovat pouze soubory potřebné pro vývoj, to znamená záhlaví, statické knihovny, symbolické odkazy sdílených knihoven, soubory pkg-config, dokumentaci API nebo jakýkoli jiný skript, který je užitečný pouze při vývoji pro cíl. software.

Vývojový balíček by měl záviset na balíčcích, které se vyžadují k propojení s poskytnutými sdílenými knihovnami, tj. pokud `libfoo` poskytuje sdílenou knihovnu `libfoo.so.2` a propojení potřebuje `-lbar` , balíček poskytující sdílenou knihovnu `libbar` by měl být přidán jako závislost ; a s největší pravděpodobností bude záviset na jeho vývojovém balíčku.

Pokud vývojový balíček poskytuje soubor `pkg-config` , měli byste ověřit, jaké závislosti potřebuje balíček pro dynamické nebo statické propojení, a přidat příslušné `development` balíčky jako závislosti.

Vývojové balíčky pro jazyky C a C++ obvykle `vmove` následující podmnožinu souborů z hlavního balíčku:

- Záhlaví souborů `usr/include`
- Statické knihovny `usr/lib/*.a`
- Symbolické odkazy sdílené knihovny `usr/lib/*.so`
- Pravidla Cmake `usr/lib/cmake` `usr/share/cmake`
- Zabalte konfigurační soubory `usr/lib/pkgconfig` `usr/share/pkgconfig`
- Autoconf makra `usr/share/aclocal`
- Soubory XML pro introspekci Gobject `usr/share/gir-1.0`
- Vala vazby `usr/share/vala`

<a id="pkgs_data"></a>

#### Datové balíčky

Dalším běžným typem dílčího balíčku je dílčí balíček `-data` . Tento typ dílčího balíku se používá k rozdělení na architektuře nezávislé, velké (ger) nebo velké množství dat z hlavní části balíku a části závislé na architektuře. Je na vás, abyste se rozhodli, zda má podbalíček `-data` pro váš balíček smysl. Tento typ je běžný pro hry (grafika, zvuk a hudba), knihovny součástí (CAD) nebo materiál karet (mapy). Hlavní balíček pak musí mít `depends="${pkgname}-data-${version}_${revision}"` , možná kromě jiných, neautomatických závislostí.

<a id="pkgs_documentation"></a>

#### Balíčky dokumentace

Balíčky určené pro interakci uživatele ne vždy bezpodmínečně vyžadují svou dokumentační část. Uživatel, který nechce např. vyvíjet s Qt5, nebude muset instalovat (obrovský) balíček qt5-doc. Odborník to nemusí potřebovat nebo se rozhodne používat online verzi.

Obecně je balíček `-doc` užitečný, pokud lze hlavní balíček použít s dokumentací i bez dokumentace a velikost dokumentace není opravdu malá. Základní balíček a podbalíček `-devel` by měly být malé, aby při sestavování balíčků závislých na konkrétním balíčku nebylo nutné bezdůvodně instalovat velké množství dokumentace. Velikost části dokumentace by tedy měla být vaším vodítkem při rozhodování, zda oddělit podbalíček `-doc` či nikoli.

<a id="pkgs_python"></a>

#### Python balíčky

Balíčky Pythonu by měly být sestaveny se stylem sestavení `python3-module` , pokud je to možné. Tím se nastaví některé proměnné prostředí potřebné k umožnění křížové kompilace. Je také možná podpora umožňující sestavení modulu python pro více verzí z jedné šablony. Styl sestavení `python3-pep517` poskytuje prostředky k sestavení pythonových balíčků, které poskytují definici sestavovacího systému v souladu s [PEP 517](https://www.python.org/dev/peps/pep-0517/) bez tradičního skriptu `setup.py` . Styl sestavení `python3-pep517` neposkytuje konkrétní backend sestavení, takže balíčky budou muset přidat vhodného poskytovatele backendu do `hostmakedepends` .

Balíčky Pythonu, které se spoléhají na `python3-setuptools` by obecně měly mapovat závislosti `setup_requires` v `setup.py` na `hostmakedepends` v šabloně a `install_requires` závislosti na `depends` v šabloně; include `python3` in `depends` , pokud neexistují žádné další závislosti na pythonu. Pokud balíček obsahuje zkompilované rozšíření, měly by být balíčky `python3-devel` přidány do `makedepends` , stejně jako všechny balíčky python, které také poskytují nativní knihovny, se kterými bude rozšíření propojeno (i když je tento balíček také zahrnut v `hostmakedepends` , aby vyhovoval `setuptools` ) .

**Poznámka** : Python `setuptools` se pokusí použít `pip` nebo `EasyInstall` k načtení chybějících závislostí v době sestavování. Pokud si po sestavení balíčku všimnete varování o ukončení podpory `EasyInstall` nebo vejcích python přítomných v `${wrksrc}/.eggs` , pak by tyto balíčky měly být přidány do `hostmakedepends` .

Následující proměnné mohou ovlivnit, jak jsou balíčky python sestavovány a konfigurovány v době po instalaci:

- `pycompile_module` : Ve výchozím nastavení jsou soubory a adresáře nainstalované do `usr/lib/pythonX.Y/site-packages` , kromě `*-info` a `*.so` , v době instalace kompilovány jako python moduly. Tato proměnná očekává jejich podmnožinu, která by měla být kompilována po bajtech, pokud je výchozí hodnota nesprávná. Více modulů pythonu může být specifikováno oddělených mezerami, Příklad: `pycompile_module="foo blah"` . Pokud modul pythonu nainstaluje soubor do `site-packages` , nikoli do adresáře, použijte název souboru, Příklad: `pycompile_module="fnord.py"` .

- `pycompile_dirs` : tato proměnná očekává adresáře pythonu, které by měly být rekurzivně `byte-compiled` bajty cílovou verzí pythonu. To se liší od `pycompile_module` tím, že lze zadat libovolnou cestu, Příklad: `pycompile_dirs="usr/share/foo"` .

- `python_version` : tato proměnná očekává podporovanou hlavní verzi Pythonu. Ve většině případů je verze odvozena z shebang, instalační cesty nebo stylu sestavení. Vyžaduje se pouze pro některé vícejazyčné aplikace (např. aplikace je napsána v C, zatímco příkaz je napsán v Pythonu) nebo pouze pro ty, které jsou v jednom souboru Pythonu, které jsou uloženy v `/usr/bin` . Pokud je `python_version` nastaveno na `ignore` , shebangy obsahující python nebudou přepsány. Toto použijte pouze v případě, že by balíček neměl používat systémovou verzi pythonu.

- `python_extras` : Doplňky modulu Python, které je třeba vzít v úvahu při ověřování závislostí modulu Python. Lze použít k zajištění kontroly dalších sad závislostí. Příklad: `python_extras="all"` .

- `nopyprovides` : pokud je nastaveno, nevytvářet `provides` položky pro moduly Pythonu v balíčku.

- `noverifypydeps` : pokud je nastaveno, neověřujte závislosti modulu Python.

V šablonách je také definována sada užitečných proměnných:

Proměnná | Hodnota
--- | ---
py2_ver | 2.X
py2_lib | usr/lib/python2.X
py2_sitelib | usr/lib/python2.X/site-packages
py2_inc | usr/include/python2.X
py3_ver | 3.X
py3_lib | usr/lib/python3.X
py3_sitelib | usr/lib/python3.X/site-packages
py3_inc | usr/include/python3.Xm

> POZNÁMKA: Očekává se, že musí být vygenerovány další subpkg, aby bylo možné sbalit více verzí pythonu.

<a id="pkgs_go"></a>

#### Přejít na balíčky

Pokud je to možné, balíčky Go by měly být sestaveny stylem `go` build. Styl sestavení `go` se stará o stahování závislostí Go a nastavení křížové kompilace.

Následující proměnné šablony ovlivňují způsob, jakým jsou sestavovány balíčky Go:

- `go_import_path` : Cesta k importu balíčku obsaženého v souboru distfile, jak by byla použita s `go get` . Například program `hub` GitHub má cestu importu `github.com/github/hub` . Tato proměnná je povinná.
- `go_package` : Mezerou oddělený seznam cest importu balíčků, které by měly být sestaveny. Výchozí hodnota je `go_import_path` .
- `go_build_tags` : Volitelný, mezerami oddělený seznam značek sestavení, které se mají předat Go.
- `go_mod_mode` : Režim stahování modulu, který se má použít. Může být `off` , aby se ignorovaly všechny soubory go.mod, `default` se používá výchozí chování Go nebo cokoli, co přijímá `go build -mod MODE` . Výchozí hodnota je `vendor` , pokud existuje adresář dodavatele, jinak `default` .
- `go_ldflags` : Argumenty, které se mají předat propojovacím krokům nástroje go.

Následující proměnné prostředí ovlivňují, jak jsou balíčky Go sestaveny:

- `XBPS_MAKEJOBS` : Hodnota předaná do parametru `-p` parametru `go install` pro řízení paralelismu kompilátoru Go.

Občas je nutné provádět operace ze stromu zdroje Go. To obvykle potřebují programy používající go-bindata nebo jinak připravující některá aktiva. Pokud je to možné, proveďte to v pre_build(). Cesta ke zdroji balíčku uvnitř `$GOPATH` je dostupná jako `$GOSRCPATH` .

<a id="pkgs_haskell"></a>

#### Haskell balíčky

Haskell balíčky lze sestavit buď stylem `cabal` , nebo `haskell-stack` . Použijte ten, který je pohodlnější nebo lépe podporovaný upstreamem. Někdy je možný pouze jeden z těchto dvou. U balíčků, které obsahují haskellové části, ale používají jiný styl sestavení, jako je `gnu-makefile` , nezapomeňte použít `haskell` build helper.

Následující proměnné ovlivňují, jak jsou balíčky sestavovány pomocí cabal:

- `cabal_index_state` : Stav indexu hackage cabal, který se má použít pro načítání závislostí. Zdrojový balíček projektu Haskell by měl obsahovat soubor freeze, který nastavuje stav indexu, některé jej také nastavují ve svém souboru projektu cabal. Pokud tomu tak není, musí být v šabloně balíčku nastaveno časové razítko ISO. Například `2025-07-05T14:01:16Z` .
- `configure_args` : Argumenty předávané `cabal configure` . Krok configure generuje soubor `cabal.project.local` .
- `make_build_args` : Argumenty předávané příkazu `cabal build` .
- `make_build_target` : Cíl předán `cabal build` .
- `make_check_args` : Argumenty předané do `cabal test` .
- `make_check_target` : Cíl testu byl předán cabalu místo "test".
- `make_install_target` : Cíl předán `cabal install` .

A tyto proměnné ovlivňují, jak jsou balíčky sestavovány pomocí stack:

- `stackage` : Verze Stackage použitá k sestavení balíčku, např `lts-3.5` . Alternativně:
    - Pro projekt můžete připravit konfiguraci `stack.yaml` a vložit ji do `files/stack.yaml` .
    - Pokud je ve zdrojových souborech přítomen soubor `stack.yaml` , bude použit.
- `make_build_args` : Toto je předáno tak, jak je, do `stack build ...` , takže tam můžete přidat své parametry `--flag ...`

Pro opravu závislostí balíčků Haskell je nutné je explicitně načíst z Hackage přidáním do `distfiles` místo aby je stahoval Cabal nebo Stack. Po extrahování a opravě lze cestu k opravené verzi přidat k `packages` v souboru `cabal.project` nebo `stack.yaml` . Stack je automaticky vyhledá, pokud soubor `stack.yaml` neexistuje, prohledáním adresáře. Nástroj pro sestavení pak použije opravenou verzi závislosti, místo aby ji stahoval z Hackage.

<a id="pkgs_font"></a>

#### Balíčky písem

Balíčky písem se píší velmi jednoduše, vždy se nastavují pomocí následujících proměnných:

- `depends="font-util"` : protože jsou vyžadovány pro regeneraci mezipaměti písem během instalace/odebírání balíčku
- `font_dirs` : který by měl být nastaven na adresář, kam balíček instaluje své fonty

<a id="pkg_rename"></a>

### Přejmenování balíčku

- Vytvořte prázdný balíček se starým názvem v závislosti na novém balíčku. To je nezbytné pro poskytování aktualizací systémů, kde je již nainstalován starý balíček. Toto by měl být podbalíček nového, kromě případů, kdy se číslo verze nového balíčku snížilo: pak vytvořte samostatnou šablonu pomocí staré verze a zvýšené revize.
- Upravte odkazy na balíček v jiných šablonách a common/shlibs.
- Nenastavujte `replaces=` , může to mít za následek odstranění obou balíků ze systémů pomocí xbps.

<a id="pkg_remove"></a>

### Odebírání balíčku

Následuje seznam věcí, které je třeba udělat, aby bylo zaručeno, že odstranění šablony balíčků a potažmo jeho binárních balíčků z repozitářů Void Linuxu proběhne hladce.

Před odstraněním šablony balíčku:

- Zaručit, že žádný balíček na něm nebo na některém z jeho dílčích balíčků nezávisí. Za tímto účelem můžete v šablonách vyhledat odkazy na balíček pomocí `grep -r '\bpkg\b' srcpkgs/` .
- Záruka, že žádný balíček nezávisí na shlibs, které poskytuje.

Při odstraňování šablony balíčku:

- Odstraňte všechny symbolické odkazy, které ukazují na balíček. `find srcpkgs/ -lname <pkg>` by mělo stačit.
- Pokud balíček obsahuje shliby, ujistěte se, že jste je odstranili z common/shlibs.
- Některé balíčky používají záplaty a soubory z jiných balíčků pomocí symbolických odkazů, obvykle jsou tyto balíčky stejné, ale byly rozděleny, aby se předešlo cyklickým závislostem. Ujistěte se, že balíček, který odstraňujete, není zdrojem těchto záplat/souborů.
- Odebrat šablonu balíčku.
- Přidejte `pkgname<=version_revision` do `replaces` proměnné šablony `removed-packages` . Všechny odstraněné dílčí balíčky by měly být přidány také. Tím se balíček odinstaluje ze systémů, kde je nainstalován.
- Odstraňte balíček z indexu úložiště nebo kontaktujte člena týmu, který tak může učinit.

<a id="xbps_triggers"></a>

### Spouštěče XBPS

Spouštěče XBPS jsou sbírkou úryvků kódu poskytovaných balíčkem `xbps-triggers` , které se přidávají do skriptů INSTALL/REMOVE balíčků buď ručně nastavením proměnné `triggers` v šabloně, nebo automaticky, když jsou splněny specifické podmínky.

Následuje seznam všech dostupných spouštěčů, jejich aktuální stav, co každý z nich dělá a jaké podmínky musí splňovat, aby byl automaticky zahrnut do balíčku.

Toto není úplný přehled balíčku. Doporučuje se přečíst odkazované proměnné a samotné spouštěče.

<a id="triggers_appstream_cache"></a>

#### appstream-cache

Spouštěč appstream-cache je zodpovědný za opětovné sestavení mezipaměti metadat appstreamu.

Během instalace spustí `appstreamcli refresh-cache --verbose --force --datapath $APPSTREAM_PATHS --cachepath var/cache/app-info/gv` . Ve výchozím nastavení jsou APPSTREAM_PATHS všechny cesty, které bude appstreamcli hledat pro soubory metadat.

Adresáře prohledávané appstreamcli jsou:

- `usr/share/appdata`
- `usr/share/app-info`
- `var/lib/app-info`
- `var/cache/app-info`

Během odstraňování balíčku `AppStream` dojde k odstranění adresáře `var/cache/app-info/gv` .

Automaticky se přidá do balíčků, které mají soubory XML v jednom z adresářů prohledaných appstreamcli.

<a id="triggers_binfmts"></a>

#### binfmts

Spouštěč binfmts je zodpovědný za registraci a odstranění libovolných spustitelných binárních formátů, známých jako binfmts.

Během instalace/odstranění používá `update-binfmts` z balíčku `binfmt-support` k registraci/odstranění položek z libovolné databáze spustitelných binárních formátů.

Je automaticky přidán do balíčků, které obsahují soubory v `usr/share/binfmts` . Tyto soubory by měly být ve formátu `update-binfmts` a budou importovány pomocí `update-binfmts --import` .

I když to není preferováno, spouštěč lze přidat také pomocí proměnné `binfmts` , která by měla obsahovat řádky definující binfmts pro registraci:

```
/path/to/interpreter [update-binfmts binary format specification arguments ...]
...
```

Viz [`update-binfmts(8)`](https://man.voidlinux.org/man8/update-binfmts.8) pro více podrobností.

<a id="triggers_dkms"></a>

#### dkms

Spouštěč dkms je zodpovědný za kompilaci a odstranění dynamických modulů jádra balíčku.

Během instalace trigger zkompiluje a nainstaluje dynamický modul pro všechny `linux` balíčky, které mají nainstalovaný odpovídající balíček linux-headers. Během odebírání bude odebrán odpovídající modul

Chcete-li zahrnout spouštěč, použijte proměnnou `dkms_modules` , protože spouštěč nedělá nic, pokud není definován.

<a id="triggers_gconf_schemas"></a>

#### schémata gconf

Spouštěč gconf-schemas je zodpovědný za registraci a odstranění souborů .schemas a .entries do adresáře databáze schémat.

Během instalace používá `gconftool-2` k instalaci souborů .schemas a .entries do `usr/share/gconf/schemas` . Během odstraňování používá `gconftool-2` k odstranění položek a schémat patřících k balíčku, který je odstraňován z databáze.

Chcete-li jej zahrnout, přidejte do `triggers` `gconf-schemas` a přidejte vhodná .schemas do proměnné `gconf_schemas` a .entries do `gconf_entries` .

Automaticky se přidává do balíčků, které mají jako adresář `/usr/share/gconf/schemas` . Všechny soubory s příponou schématu v tomto adresáři jsou předány spouštěči.

<a id="triggers_gdk_pixbuf_loaders"></a>

#### gdk-pixbuf-loadery

Spouštěč gdk-pixbuf-loaders je zodpovědný za udržování mezipaměti zavaděčů GDK Pixbuf.

Během instalace spouští `gdk-pixbuf-query-loaders --update-cache` a také smaže zastaralý soubor `etc/gtk-2.0/gdk-pixbuf.loaders` pokud existuje. Během odstraňování balíčku gdk-pixbuf odstraní soubor mezipaměti, pokud je přítomen. Normálně na `usr/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache` .

Lze jej přidat definováním `gdk-pixbuf-loaders` v proměnné `triggers` . Je také automaticky přidán do každého balíčku, který má jako adresář k dispozici cestu `usr/lib/gdk-pixbuf-2.0/2.10.0/loaders` .

<a id="triggers_gio_modules"></a>

#### gio-moduly

Spouštěč gio-modules je zodpovědný za aktualizaci mezipaměti modulu Glib GIO moduly `gio-querymodules` z balíčku `glib`

Během instalace a odebrání pouze spustí `gio-querymodules` , aby aktualizoval soubor mezipaměti přítomný pod `usr/lib/gio/modules` .

Automaticky se přidává do balíčků, které mají jako adresář `/usr/lib/gio/modules` .

<a id="triggers_gsettings_schemas"></a>

#### gsettings-schémata

Spouštěč gsettings-schemas je zodpovědný za kompilaci souborů schématu Glib Glib GSettings XML během instalace a odstranění zkompilovaných souborů během odstraňování.

Během instalace používá `glib-compile-schemas` z `glib` ke kompilaci schémat do souborů s příponou .compiled do `/usr/share/glib-2.0/schemas` .

Během odstraňování balíčku glib smaže všechny soubory v `/usr/share/glib-2.0/schemas` , které končí příponou .compiled.

Je automaticky přidán do balíčků, které mají jako adresář `/usr/share/glib-2.0/schemas` .

<a id="triggers_gtk_icon_cache"></a>

#### gtk-ikona-mezipaměť

Spouštěč gtk-icon-cache je zodpovědný za aktualizaci mezipaměti ikon gtk+.

Během instalace používá `gtk-update-icon-cache` k aktualizaci mezipaměti ikon.

Při odstraňování balíčku gtk+ smaže soubor `icon-theme.cache` v adresářích definovaných proměnnou `gtk_iconcache_dirs` .

Automaticky se přidává do balíčků, které mají jako adresář k dispozici `/usr/share/icons` , všechny adresáře v tomto adresáři mají svou absolutní cestu předán spouštěči.

<a id="triggers_gtk_immodules"></a>

#### gtk-immodules

Spouštěč gtk-immodules je zodpovědný za aktualizaci souboru modulů IM (Input Method) pro gtk+.

Během instalace používá `gtk-query-immodules-2.0 --update-cache` k aktualizaci souboru mezipaměti. Odstraní také zastaralý konfigurační soubor `etc/gtk-2.0/gtk.immodules` pokud existuje.

Během odstraňování balíčku `gtk+` odstraní soubor mezipaměti, který se nachází na `usr/lib/gtk-2.0/2.10.0/immodules.cache` .

Automaticky se přidává do balíčků, které mají jako adresář `/usr/lib/gtk-2.0/2.10.0/immodules` .

<a id="triggers_gtk_pixbuf_loaders"></a>

#### gtk-pixbuf-loadery

gtk-pixbuf-loaders je starý název pro aktuální spouštěč `gdk-pixbuf-loaders` a je v procesu odstraňování. V současné době se znovu spouští do `gdk-pixbuf-loaders` jako opatření kompatibility.

Informace o tom, jak to funguje, najdete v [gdk-pixbuf-loaders](#triggers_gdk_pixbuf_loaders) .

<a id="triggers_gtk3_immodules"></a>

#### gtk3-immodules

Spouštěč gtk3-immodules je zodpovědný za aktualizaci souboru modulů IM (Input Method) pro gtk+3.

Během instalace spustí `gtk-query-immodules-3.0 --update-cache` pro aktualizaci souboru mezipaměti. Také odstraní zastaralý konfigurační soubor `etc/gtk-3.0/gtk.immodules` pokud existuje.

Během odstraňování balíčku `gtk+3` odstraní soubor mezipaměti, který se nachází na `usr/lib/gtk-3.0/3.0.0/immodules.cache` .

Automaticky se přidává do balíčků, které mají jako adresář `/usr/lib/gtk-3.0/3.0.0/immodules` .

<a id="triggers_hwdb.d_dir"></a>

#### hwdb.d-dir

Spouštěč hwdb.d-dir je zodpovědný za aktualizaci hardwarové databáze.

Během instalace a odebrání spouští `usr/bin/udevadm hwdb --root=. --update` .

Je automaticky přidán do balíčků, které mají jako adresář `/usr/lib/udev/hwdb.d` .

<a id="triggers_info_files"></a>

#### info-soubory

Spouštěč info-files je zodpovědný za registraci a odregistrování GNU informačních souborů balíčku.

Kontroluje existenci informačních souborů, které jsou mu předkládány, a zda běží pod jinou architekturou.

Během instalace používá `install-info` k registraci informačních souborů do `usr/share/info` .

Během odstraňování používá `install-info --delete` k odstranění informačních souborů z registru umístěného na `usr/share/info` .

Pokud běží pod jinou architekturou, pokusí se použít utilitu `install-info` hostitele.

<a id="triggers_initramfs_regenerate"></a>

#### initramfs-regenerate

Spouštěč initramfs-regenerate spustí regeneraci všech obrazů initramfs jádra po instalaci nebo odstranění balíčku. O spoušť je třeba požádat ručně.

Tento háček je pravděpodobně nejužitečnější pro balíčky DKMS, protože poskytuje prostředek pro zahrnutí nově zkompilovaných modulů jádra do obrazů initramfs pro všechna aktuálně dostupná jádra. Při použití v balíčku DKMS se doporučuje ručně zahrnout spouštěč `dkms` *před* spouštěč `initramfs-regenerate` pomocí např.

```
```
triggers="dkms initramfs-regenerate"
```
```

Ačkoli `xbps-src` automaticky zahrne spouštěč `dkms` kdykoli je nainstalován `dkms_modules` , automatické přidání přijde *po* `initramfs-regenerate` , což způsobí, že obrazy initramfs budou znovu vytvořeny před kompilací modulů.

Ve výchozím nastavení spouštěč používá `dracut --regenerate-all` k opětovnému vytvoření obrázků initramfs. Pokud `/etc/default/initramfs-regenerate` existuje a definuje `INITRAMFS_GENERATOR=mkinitcpio` , spouštěč místo toho použije `mkinitcpio` a zacyklí všechny verze jádra, pro které se zdá, že jsou nainstalovány moduly. Případně nastavení `INITRAMFS_GENERATOR=none` zcela zakáže regeneraci obrazu.

<a id="triggers_kernel_hooks"></a>

#### kernel-háky

Spouštěč kernel-hooks je zodpovědný za spouštění skriptů během instalace/odebírání balíčků jádra.

Dostupné cíle jsou před instalací, před odstraněním, po instalaci a po odstranění.

Při spuštění se pokusí spustit všechny spustitelné soubory nalezené pod `etc/kernel.d/$TARGET` . Proměnná `TARGET` je jedním ze 4 cílů dostupných pro spouštěč. Vytvoří také adresář, pokud není přítomen.

Během aktualizací se nebude pokoušet spustit žádné spustitelné soubory, když běží s cílem před odstraněním.

Je přidána automaticky, pokud je definována pomocná proměnná `kernel_hooks_version` . Není však povinné jej mít definované.

<a id="triggers_mimedb"></a>

#### mimedb

Spouštěč mimedb je zodpovědný za aktualizaci databáze shared-mime-info.

Ve všech spuštěních se pouze spustí `update-mime-database -n usr/share/mime` .

Je automaticky přidán do balíčků, které mají jako adresář k dispozici `/usr/share/mime` .

<a id="triggers_mkdirs"></a>

#### mkdirs

Spouštěč mkdirs je zodpovědný za vytváření a odstraňování adresářů diktovaných proměnnou `make_dirs` .

Během instalace vezme proměnnou `make_dirs` a rozdělí ji do skupin po 4 proměnných.

- dir = úplná cesta k adresáři
- režim = Unixová oprávnění pro adresář
- uid = jméno vlastnícího uživatele
- gid = název vlastnící skupiny

Bude pokračovat v rozdělování hodnot `make_dirs` do skupin po 4, dokud hodnoty neskončí.

Během instalace vytvoří adresář s `dir` a poté nastaví režim s `mode` a oprávněním pomocí `uid:gid` .

Během odstraňování smaže adresář pomocí `rmdir` .

Chcete-li zahrnout tento spouštěč, použijte proměnnou `make_dirs` , protože spouštěč nedělá nic, pokud není definován.

<a id="triggers_pango_module"></a>

#### pango-moduly

Spouštěč pango-modules se aktuálně odstraňuje, protože upstream odstranil kód, který je za něj zodpovědný.

Slouží k aktualizaci souboru pango modules pomocí `pango-modulesquery` během instalace libovolného balíčku.

V současné době odstraňuje soubor `etc/pango/pango.modules` během odstraňování balíčku pango.

Může být přidán definováním `pango-modules` v proměnné `triggers` a nemá žádný způsob, jak se automaticky přidat do balíčku.

<a id="triggers_pycompile"></a>

#### pycompile

Spouštěč pycompile je zodpovědný za kompilaci kódu pythonu do nativního bajtkódu a odstranění generovaného bajtkódu.

Během instalace zkompiluje veškerý kód pythonu pod cestami, které jsou uvedeny v `pycompile_dirs` a všechny moduly popsané v `pycompile_module` do nativního bytecode a aktualizuje mezipaměť ldconfig(8).

Během odstraňování odstraní veškerý nativní bytecode a aktualizuje mezipaměť ldconfig(8).

K zahrnutí tohoto spouštěče použijte proměnné `pycompile_dirs` a `pycompile_module` . Spouštěč neprovede nic, pokud není definována alespoň jedna z těchto proměnných.

Proměnnou `python_version` lze nastavit tak, aby řídila chování spouštěče.

<a id="triggers_register_shell"></a>

#### registr-shell

Spouštěč registry-shell je zodpovědný za registraci a odstraňování položek shellu do `etc/shells` .

Během instalace připojí soubor `etc/shells` s novým shellem a také změní oprávnění k souboru na `644` .

Během odstraňování použije `sed` k odstranění shellu ze souboru.

Chcete-li zahrnout tento spouštěč, použijte proměnnou `register_shell` , protože spouštěč nedělá nic, pokud není definován.

<a id="triggers_system_accounts"></a>

#### systémové účty

Spouštěč systémových účtů je zodpovědný za vytváření a deaktivaci systémových účtů a skupin.

Během odstraňování deaktivuje účet nastavením Shell na /bin/false, Home na /var/empty a připojením '- pro odinstalovaný balíček $pkgname' do Popisu. Příklad: `transmission unprivileged user - for uninstalled package transmission`

Tento spouštěč lze použít pouze pomocí proměnné `system_accounts` .

<a id="triggers_texmf_dist"></a>

#### texmf-dist

Spouštěč texmf-dist je zodpovědný za regeneraci texmf databází TeXLive.

Během instalace i odebrání regeneruje databáze texhash i formátování pomocí `texhash` a `fmtutil-sys` a přidává nebo odstraňuje jakékoli nové hashe nebo formáty.

Běží na každém balíčku, který změní /usr/share/texmf-dist. To je pravděpodobně přehnané, ale je to mnohem čistší než kontrola každého adresáře formátu a každého adresáře, který je hašován. Navíc je velmi pravděpodobné, že jakýkoli balíček dotýkající se /usr/share/texmf-dist stejně vyžaduje jeden z těchto spouštěčů.

<a id="triggers_update_desktopdb"></a>

#### update-desktopdb

Spouštěč update-desktopdb je zodpovědný za aktualizaci systémové databáze MIME.

Během instalace se spustí `update-desktop-database usr/share/applications` což povede k vytvoření souboru mezipaměti na `usr/share/applications/mimeinfo.cache` .

Během odebírání balíčku `desktop-file-utils` se odstraní soubor mezipaměti, který byl vytvořen během instalace.

Je automaticky přidán do balíčků, které mají `/usr/share/applications` k dispozici jako adresář.

<a id="triggers_x11_fonts"></a>

#### x11-fonty

Spouštěč x11-fonts je zodpovědný za opětovné sestavení souborů fonts.dir a fonts.scale pro balíčky, které instalují fonty X11, a aktualizuje mezipaměť fontconfig pro tyto fonty.

Během instalace a odstranění spouští `mkfontdir` , `mkfontscale` a `fc-cache` pro všechny adresáře písem, které byly zadány přes proměnnou `font_dirs` .

Chcete-li zahrnout tento spouštěč, použijte proměnnou `font_dirs` , protože spouštěč nedělá nic, pokud není definován.

<a id="triggers_xml_catalog"></a>

#### xml-katalog

Spouštěč xml-catalog je zodpovědný za registraci a odstraňování položek katalogu SGML/XML.

Během instalace používá `xmlcatmgr` k registraci všech katalogů, které mu předávají proměnné `sgml_entries` a `xml_entries` v `usr/share/sgml/catalog` a `usr/share/xml/catalog` .

Během odstraňování používá `xmlcatmgr` k odstranění všech katalogů, které mu byly předány proměnnými `sgml_entries` a `xml_entries` v `usr/share/sgml/catalog` a `usr/share/xml/catalog` .

Chcete-li zahrnout tento spouštěč, použijte proměnnou `sgml_entries` nebo/a proměnnou `xml_entries` , protože spouštěč nebude dělat nic, pokud nebude žádná z nich definována.

<a id="documentation"></a>

### Zrušte konkrétní dokumentaci

Chcete-li zdokumentovat podrobnosti o konfiguraci a použití balíčku specifické pro Void Linux, které nepokrývá upstream dokumentace, vložte poznámky do `srcpkgs/<pkgname>/files/README.voidlinux` a nainstalujte pomocí `vdoc "${FILESDIR}/README.voidlinux"` .

<a id="notes"></a>

### Poznámky

- Ujistěte se, že veškerý software je nakonfigurován tak, aby používal předponu `/usr` .

- Binární soubory by měly být vždy nainstalovány v `/usr/bin` .

- Manuálové stránky by měly být vždy instalovány v `/usr/share/man` .

- Pokud software poskytuje **sdílené knihovny** a hlavičky, pravděpodobně byste měli vytvořit `development package` , který obsahuje `headers` , `static libraries` a další soubory potřebné pro vývoj (není vyžadováno za běhu).

- Pokud aktualizujete balíček, buďte opatrní s nárazy SONAME, před odesláním nových aktualizací zkontrolujte nainstalované soubory ( `./xbps-src show-files pkg` ).

- Ujistěte se, že binární soubory nejsou odstraněny softwarem, nechejte to udělat xbps-src; jinak `debug` balíčky nebudou mít ladicí symboly.

<a id="contributing"></a>

### Přispívání přes git

Pro začátek si na GitHubu [vytvořte fork](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/fork-a-repo) void-linux repozitáře `void-packages` a naklonujte ho:

```
$ git clone git@github.com:<user>/void-packages.git
```

Viz [CONTRIBUTING.md](./CONTRIBUTING.md) pro informace o tom, jak formátovat vaše odevzdání a další tipy pro přispívání.

Jakmile provedete změny ve vašem `forked` úložišti, odešlete žádost o stažení githubu.

Chcete-li, aby byl váš rozvětvený repozitář vždy aktuální, nastavte `upstream` dálkové ovládání tak, aby načítalo nové změny:

```
$ git remote add upstream https://github.com/void-linux/void-packages.git
$ git pull --rebase upstream master
```

<a id="help"></a>

### Pomoc

Pokud po přečtení této `manual` stále potřebujete nějakou pomoc, připojte se k nám na `#xbps` přes IRC na `irc.libera.chat` .
