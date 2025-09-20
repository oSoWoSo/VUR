# Přispívání do void-balíčků

void-packages jsou páteří distribuce Void Linux. Obsahují všechny definice pro sestavení balíčků ze zdroje.

Tento dokument popisuje, jak můžete jako přispěvatel pomoci s přidáváním balíčků, opravováním chyb a přidáváním funkcí do void-balíčků.

## Požadavky na balíček

Aby mohl být software zahrnut do úložiště Void, musí splňovat alespoň jeden z následujících požadavků. Výjimky ze seznamu jsou možné a mohou být přijaty, ale jsou extrémně nepravděpodobné. Pokud si myslíte, že máte výjimku, začněte PR a argumentujte, proč je tento konkrétní software, i když nesplňuje žádné z následujících požadavků, dobrým kandidátem pro systém Void balíčků.

1. **Systém** : Software by měl být instalován v rámci celého systému, nikoli na uživatele.

2. **Kompilováno** : Software musí být před použitím zkompilován, i když se jedná o software, který nepotřebuje celý systém.

3. **Vyžadováno** : Balíček vyžaduje jiný balíček v úložišti nebo čekající na zahrnutí.

Zejména je velmi nepravděpodobné, že budou přijata nová témata. Jednoduché skripty shellu pravděpodobně nebudou přijaty, pokud nebudou poskytovat značnou hodnotu široké uživatelské základně. Nové fonty mohou být přijaty, pokud poskytují hodnotu nad rámec estetiky (např. obsahují glyfy pro skript, který chybí v již zabalených fontech). Balíčky související s kryptoměnami (peněženky, těžaři, uzly atd.) nejsou přijímány.

Rozvětvení prohlížečů, včetně těch založených na Chromiu a Firefoxu, nejsou obecně přijímány. Takové vidlice vyžadují náročné opravy, údržbu a hodiny výstavby.

Software je třeba používat ve verzi, kterou autoři oznámili jako připravenou k použití širokou veřejností – obvykle se nazývá verze. Beta verze, libovolné revize VCS, šablony využívající tip vývojové větve pořízené v době sestavení a vydání vytvořená správcem balíčku nebudou přijaty.

## Vytvářejte, aktualizujte a upravujte balíčky ve Void svépomocí

Pokud opravdu chcete získat nový balíček nebo aktualizaci balíčku do Void Linuxu, doporučujeme vám přispět sami.

Poskytujeme [obsáhlý manuál](./Manual.md) , jak vytvářet nové balíčky. Existuje také [příručka pro xbps-src](./README.md) , která se používá k vytváření souborů balíčků ze šablon.

V této příručce předpokládáme, že máte základní znalosti o [git](http://git-scm.org) , stejně jako [o účtu GitHub](http://github.com) s [nastaveným SSH](https://docs.github.com/en/authentication/connecting-to-github-with-ssh) .

Také byste měli [nastavit e-mail](https://docs.github.com/en/account-and-profile/setting-up-and-managing-your-personal-account-on-github/managing-email-preferences/setting-your-commit-email-address) na svém účtu GitHub a v git, aby byly vaše commity správně spojeny s vaším účtem GitHub.

Chcete-li začít, [rozvětvte](https://help.github.com/articles/fork-a-repo) repozitář git void-linux `void-packages` na GitHubu a naklonujte jej:

```
$ git clone git@github.com:<user>/void-packages.git
```

Chcete-li, aby byl váš rozvětvený repozitář aktuální, nastavte `upstream` dálkové ovládání tak, aby načítalo nové změny:

```
$ git remote add upstream https://github.com/void-linux/void-packages.git
$ git pull --rebase upstream master
```

To lze také provést pomocí nástroje `github-cli` :

```
$ gh repo fork void-linux/void-packages
$ gh repo clone <user>/void-packages
```

Tím se automaticky nastaví `upstream` remote, takže `git pull --rebase upstream master` lze stále používat k udržování vaší vidlice aktuální.

Důrazně se nedoporučuje používat k provádění změn webový editor GitHub, protože k úpravě a testování změn budete stejně muset naklonovat repo.

Důrazně se nedoporučuje používat `master` větev vaší vidlice pro přispívání. Může to způsobit mnoho problémů s aktualizací vašeho požadavku na stažení (také nazývaného PR) a otevřením více PR najednou. Chcete-li vytvořit novou větev:

```
$ git checkout master -b <a-descriptive-name>
```

### Vytvoření nové šablony

K vytvoření nových šablon můžete použít pomocný nástroj `xnew` z balíčku [xtools](https://github.com/leahneukirchen/xtools) :

```
$ xnew pkgname subpkg1 subpkg2 ...
```

Šablony musí mít název `void-packages/srcpkgs/<pkgname>/template` , kde `pkgname` je stejný jako proměnná `pkgname` v šabloně.

Chcete-li získat hlubší informace o obsahu souborů šablon, přečtěte si prosím [příručku](./Manual.md) a nezapomeňte procházet existující soubory šablon v adresáři `srcpkgs` tohoto úložiště, kde najdete konkrétní příklady.

### Aktualizace šablony

Aktualizace šablony bude minimálně sestávat ze změny `version` a `checksum` , pokud došlo ke změně upstream verze, a/nebo `revision` , pokud je potřeba změna specifická pro šablonu (např. oprava, oprava atd.). V závislosti na tom, jaké změny provedl upstream, mohou být nutné další změny šablony.

Kontrolní součet lze automaticky aktualizovat pomocí pomocníka `xgensum` z balíčku [xtools](https://github.com/leahneukirchen/xtools) :

```
$ xgensum -i <pkgname>
```

### Přijetí šablony

Pokud je šablona osiřelá (spravuje `orphan@voidlinux.org` ) nebo aktuální `maintainer` nepřispěl do Void déle než rok, může správce šablony převzít někdo jiný. Aby bylo zajištěno, že šablona dostane potřebnou péči, měli by uživatelé šablony být obeznámeni s balíčkem a měli by mít zavedenou historii příspěvků do Void. Ti, kteří přispěli několika aktualizacemi, zejména pro danou šablonu, jsou dobrými kandidáty na správu šablon.

Při další změně je nejlepší šablonu přijmout. Při přijímání šablony přidejte své jméno nebo uživatelské jméno a e-mail do pole `maintainer` v šabloně a zmiňte přijetí ve zprávě odevzdání, například:

```
libfoo: update to 1.2.3, adopt.
```

### Osirotování šablony

Pokud si již nepřejete udržovat šablonu, můžete se odebrat jako správce nastavením pole `maintainer` v šabloně na `Orphaned <orphan@voidlinux.org>` . Zpráva o odevzdání by to měla zmínit, například:

```
libfoo: orphan.
```

Při osamocení není nutné provádět další změny v šabloně a není nutné ani inkrementovat revizi (spouštět nové sestavení).

### Potvrzení změn

Po provedení změn zkontrolujte, zda se balíček úspěšně sestavil. Z adresáře nejvyšší úrovně vaší lokální kopie úložiště `void-packages` spusťte:

```
$ ./xbps-src pkg <pkgname>
```

Váš balíček se musí úspěšně sestavit alespoň pro x86, ale doporučujeme také vyzkoušet cross-build pro armv6l*, např.:

```
$ ./xbps-src -a armv6l pkg <pkgname>
```

Při sestavování pro `x86_64*` nebo `i686` se důrazně doporučuje sestavování s příznakem `-Q` nebo s `XBPS_CHECK_PKGS=yes` nastaveným v `etc/conf` (pro spuštění fáze kontroly). Také nové balíčky a aktualizace nebudou přijaty, pokud nebyly otestovány instalací a spuštěním balíčku.

Až dokončíte práci na souboru šablony, zkontrolujte jej pomocí pomocníka `xlint` z balíčku [xtools](https://github.com/leahneukirchen/xtools) :

```
$ xlint template
```

Pokud `xlint` hlásí nějaké problémy, vyřešte je před tím, než se zavážete.

Jakmile provedete a ověříte změny v šabloně balíčku a/nebo jiných souborech, proveďte jedno potvrzení pro každý balíček (včetně všech změn v jeho dílčích balíčcích). Každá zpráva potvrzení by měla mít jeden z následujících formátů:

- pro nové balíčky použijte `New package: <pkgname>-<version>` ( [příklad](https://github.com/void-linux/void-packages/commit/8ed8d41c40bf6a82cf006c7e207e05942c15bff8) ).

- pro aktualizace balíčku použijte `<pkgname>: update to <version>.` ( [příklad](https://github.com/void-linux/void-packages/commit/c92203f1d6f33026ae89f3e4c1012fb6450bbac1) ).

- pro úpravy šablony bez změny verze použijte `<pkgname>: <reason>` ( [příklad](https://github.com/void-linux/void-packages/commit/ff39c912d412717d17232de9564f659b037e95b5) ).

- pro odstranění balíčku použijte `<pkgname>: remove package` a do těla odevzdání uveďte důvod odstranění ( [příklad](https://github.com/void-linux/void-packages/commit/4322f923bdf5d4e0eb36738d4f4717d72d0a0ca4) ).

- pro změny jakéhokoli jiného souboru použijte `<filename>: <reason>` ( [příklad](https://github.com/void-linux/void-packages/commit/e00bea014c36a70d60acfa1758514b0c7cb0627d) , [příklad](https://github.com/void-linux/void-packages/commit/93bf159ce10d8e474da5296e5bc98350d00c6c82) , [příklad](https://github.com/void-linux/void-packages/commit/dc62938c67b66a7ff295eab541dc37b92fb9fb78) , [příklad](https://github.com/void-linux/void-packages/commit/e52317e939d41090562cf8f8131a68772245bdde) )

Pokud chcete své změny popsat podrobněji, vysvětlete to v těle potvrzení (oddělené od prvního řádku prázdným řádkem) ( [příklad](https://github.com/void-linux/void-packages/commit/f1c45a502086ba1952f23ace9084a870ce437bc6) ).

`xbump` , dostupný v balíčku [xtools](https://github.com/leahneukirchen/xtools) , lze použít k potvrzení nového nebo aktualizovaného balíčku:

```
$ xbump <pkgname> <git commit options>
```

`xrevbump` , dostupný také v balíčku [xtools](https://github.com/leahneukirchen/xtools) , lze použít k provedení úpravy šablony pro balíček:

```
$ xrevbump '<message>' <pkgnames...>
```

`xbump` a `xrevbump` použijí `git commit` k potvrzení změn s příslušnou zprávou odevzdání. Pro jemnější kontrolu nad odevzdáním lze konkrétní volby předat do `git commit` jejich přidáním za název balíčku.

### Spuštění požadavku na stažení

Jakmile balíček úspěšně sestavíte, můžete [vytvořit požadavek na stažení](https://docs.github.com/en/github/collaborating-with-issues-and-pull-requests/creating-a-pull-request) . Žádosti o stažení jsou také známé jako PR.

Většina požadavků na stažení by měla obsahovat pouze jeden balíček a závislosti, které ještě nejsou součástí void-packages.

Pokud provádíte aktualizace balíčků obsahujících soname bump, musíte také aktualizovat `common/shlibs` a revbump všechny balíčky, které jsou závislé. Pro každý revbump balíčku by mělo existovat potvrzení a tyto potvrzení by měly být součástí stejného požadavku na stažení.

Když ve svém požadavku na stažení provedete změny, *nezavírejte ho a znovu jej neotevírejte* . Místo toho stačí [vynutit git push](#review) a přepsat všechny staré commity. Zavírání a otevírání vašich žádostí o stažení opakovaně spamuje správce Prázdnoty.

#### Průběžná integrace

Žádosti o stažení jsou automaticky odesílány k testování kontinuální integrace (CI), aby se zajistilo, že se balíčky sestaví a projdou svými testy (na nativních sestaveních) na různých kombinacích knihovny C a architektury. Balíčky, které trvají déle než 120 minut nebo potřebují více než 14G úložiště k dokončení svého sestavení (například Firefox nebo linuxové jádro), selžou CI a měly by obsahovat `[ci skip]` v názvu nebo textu PR (pole komentáře, když PR se otevírá), aby nedošlo ke ztrátě času při vytváření CI. Použijte svůj nejlepší úsudek o době výstavby na základě vašich místních zkušeností se stavbou. Pokud při odesílání PR přeskočíte CI, sestavte a křížově sestavujte pro různé architektury lokálně, s glibc i musl, a poznamenejte si své místní výsledky v komentářích k PR. Ujistěte se, že pokrýváte 64bitové a 32bitové architektury.

Pokud si všimnete selhání v CI, ke kterému nedošlo lokálně, je to pravděpodobně proto, že jste lokálně nespustili testy. K tomu použijte `./xbps-src -Q pkg <package>` . Některé testy nebudou fungovat v prostředí CI nebo vůbec a jejich šablony by měly tyto informace zakódovat pomocí proměnné `make_check` .

Průběžná integrace také zkontroluje, zda šablony, které jste změnili, splňují naše pokyny. V tuto chvíli ne všechny balíčky splňují pravidla, takže pokud aktualizujete balíček, může hlásit chyby o místech, kterých jste se nedotkli. Neváhejte také opravit tyto chyby.

#### Posouzení

Je možné (a běžné), že žádost o stažení bude obsahovat chyby nebo recenzenti požádají o další vylepšení. Recenzenti vaši žádost o stažení okomentují a upozorní na to, které změny jsou nutné, než bude možné žádost o stažení sloučit.

Většina PR bude mít jediné potvrzení, jak je vidět [výše](#committing-your-changes) , takže pokud potřebujete provést změny v potvrzení a již máte otevřený požadavek na stažení, můžete použít následující příkazy:

```
$ git add <file>
$ git commit --amend
$ git push -f
```

Výkonnější způsob úpravy odevzdání než použití `git commit --amend` je s [git-rebase](https://git-scm.com/docs/git-rebase#_interactive_mode) , který vám umožňuje připojit se, změnit pořadí, změnit popis minulých odevzdání a další.

Případně, pokud se vyskytnou problémy s vaší historií git, můžete vytvořit další větev a poslat ji do stávajícího PR:

```
$ git checkout master -b <attempt2>
$ # do changes anew
$ git push -f <fork> <attempt2>:<branch-of-pr>
```

#### Uzavření požadavku na stažení

Jakmile použijete všechny požadované změny, recenzenti vaši žádost sloučí.

Pokud se požadavek na stažení na několik dní stane neaktivním, recenzenti vás mohou nebo nemusí upozornit, když se ho chystají zavřít. Pokud zůstane neaktivní dále, bude uzavřen.

Při revizi šablon se prosím zdržte dočasného uzavření požadavku na stažení. Místo toho zanechte komentář k PR s popisem toho, co je ještě potřeba dopracovat, [označte jej jako koncept](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/changing-the-stage-of-a-pull-request#converting-a-pull-request-to-a-draft) nebo k názvu PR přidejte „[WIP]“. Žádost o stažení zavřete, pouze pokud jste si jisti, že nechcete, aby byly zahrnuty vaše změny.

#### Publikování balíčku

Jakmile recenzenti sloučí žádost o stažení, automaticky se spustí náš [server sestavení](http://build.voidlinux.org) a sestaví všechny balíčky v žádosti o stažení pro všechny podporované platformy. Po dokončení jsou balíčky dostupné všem uživatelům Void Linuxu.

## Testování Pull Requests

I když je odpovědností tvůrce PR otestovat změny před jejich odesláním, jedna osoba nemůže otestovat všechny možnosti konfigurace, případy použití, hardware atd. Testování nových balíčků a aktualizací je vždy užitečné a je to skvělý způsob, jak začít s přispíváním. Nejprve [naklonujte úložiště,](https://github.com/void-linux/void-packages#quick-start) pokud jste tak ještě neučinili. Poté se podívejte na žádost o stažení, buď pomocí `github-cli` :

```
$ gh pr checkout <number>
```

Nebo pomocí `git` :

Pokud je vaše místní úložiště void-packages klonováno z vašeho forku, možná budete muset nejprve přidat hlavní úložiště jako vzdálené:

```
$ git remote add upstream https://github.com/void-linux/void-packages.git
```

Poté stáhněte a zkontrolujte PR (nahraďte `<remote>` buď `origin` , nebo `upstream` ):

```
$ git fetch <remote> pull/<number>/head:<branch-name>
$ git checkout <branch-name>
```

Poté [sestavte a nainstalujte](https://github.com/void-linux/void-packages#building-packages) balíček a otestujte jeho funkčnost.
