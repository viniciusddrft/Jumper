# Plano: Integrar AdMob no Jumper (Godot 4)

## 1. Baixar o plugin

- Repositorio: https://github.com/Poing-Studios/godot-admob-plugin
- Baixar a release compativel com Godot 4.x
- O download inclui duas partes:
  - `addons/admob/` (addon do editor)
  - Arquivos `.gdap` + `.aar` para `android/plugins/`

## 2. Instalar

1. Copiar a pasta `addons/admob/` para a raiz do projeto
2. Copiar os arquivos `.gdap` e `.aar` para `android/plugins/`
3. No Godot: Projeto > Configuracoes do Projeto > Plugins > Ativar "AdMob"
4. No export Android: marcar `plugins/AdMob = true`

## 3. Configurar IDs

- Criar/acessar conta em https://admob.google.com
- Criar app "Jumper" (Android, package: `com.godot.gameJumper`)
- Criar ad units:
  - **Interstitial** (tela cheia entre partidas) — anotar o ID
  - **Banner** (opcional, rodape durante menu) — anotar o ID
- IDs de teste do Google (usar durante desenvolvimento):
  - Banner: `ca-app-pub-3940256099942544/6300978111`
  - Interstitial: `ca-app-pub-3940256099942544/1033173712`

## 4. Codigo

### 4.1 Inicializar (settings.gd)

Adicionar variaveis para os ad unit IDs:

```gdscript
var ad_banner_id = "ca-app-pub-XXXX/YYYY"
var ad_interstitial_id = "ca-app-pub-XXXX/ZZZZ"
var is_mobile = OS.get_name() in ["Android", "iOS"]
```

### 4.2 Carregar e exibir ads (Main.gd)

No `_ready()` ou `new_game()`:

```gdscript
if Settings.is_mobile:
    MobileAds.initialize()
```

No `_on_Jumper_died()` — mostrar interstitial no game over:

```gdscript
func _on_Jumper_died():
    if score > highscore:
        highscore = score
        save_score()
    get_tree().call_group("circles", "implode")
    $Screens.game_over(score, highscore)
    $HUD.hide()
    if Settings.enable_music:
        fade_music()
    # Mostrar interstitial a cada X mortes para nao irritar o jogador
    _show_interstitial()
```

### 4.3 Controlar frequencia dos ads

Nao mostrar ad em TODA morte — sugestao: a cada 3 partidas.

```gdscript
var death_count = 0
var ads_every_n_deaths = 3

func _show_interstitial():
    if !Settings.is_mobile:
        return
    death_count += 1
    if death_count >= ads_every_n_deaths:
        death_count = 0
        MobileAds.load_interstitial()
        # Conectar o sinal de "loaded" para exibir quando pronto
```

## 5. Testar

1. Usar IDs de teste durante todo o desenvolvimento
2. Exportar APK com gradle build habilitado
3. Instalar no device fisico (ads nao funcionam no editor)
4. Verificar que o interstitial aparece no game over a cada 3 mortes
5. Substituir IDs de teste pelos IDs reais apenas na versao final

## 6. Checklist final antes de publicar

- [ ] Substituir IDs de teste pelos IDs reais
- [ ] Testar no device real com IDs reais
- [ ] Verificar politica de privacidade (obrigatoria para apps com ads)
- [ ] Verificar consent dialog (GDPR) se necessario para seu publico
