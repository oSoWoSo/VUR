# Detektor cyklů pro prázdné balíčky

Tento skript vyjmenovává závislosti pro balíčky v [úložišti void-packages](https://github.com/void-linux/void-packages) a identifikuje cykly závislostí v době sestavení.

Pro syntaxi příkazu spusťte `xbps-cycles.py -h` . Často může stačit spustit `xbps-cycles.py` bez argumentů. Ve výchozím nastavení bude skript hledat úložiště na `$XBPS_DISTDIR` ; pokud tato proměnná není definována, použije se místo ní aktuální adresář. Chcete-li toto chování přepsat, použijte volbu `-d` k zadání cesty k požadovanému klonu void-packages.

Standardním chováním bude vytvoření více procesů, jeden na CPU, aby se vyjmenovaly závislosti balíčků. Toto je zdaleka nejnáročnější část realizace. Chcete-li přepsat stupeň paralelismu, použijte volbu `-j` .

Závislosti lze ukládat do mezipaměti na disku, jeden soubor na balíček, v adresáři předaném volbou `-c` . Při dalším spuštění se stejnou volbou se závislosti načtou ze souboru, nikoli vypočítávají.

Selhání by měla být neškodná, ale v této rané fázi je nepravděpodobné, že by byla pěkná nebo dokonce užitečná.
