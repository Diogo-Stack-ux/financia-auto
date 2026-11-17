# Financia Auto

Aplicativo Flutter em português para planejar financiamento veicular. Interface branca com BlueAccent, cards transparentes com blur, títulos Poppins e textos Sora. As fontes e licenças estão em `assets/fonts`, sem depender de download durante o uso.

## Executar

Requer Flutter 3.50 / Dart 3.14 ou compatível, Android SDK 37, JDK 17 e Modo de Desenvolvedor habilitado no Windows para os symlinks dos plugins.

```powershell
flutter pub get
flutter run
```

Nesta máquina, se `flutter` não estiver no PATH:

```powershell
& C:\dev\flutter\bin\flutter.bat run
```

Para iOS, use macOS, Xcode e um dispositivo/simulador com iOS 15 ou superior. Android: API 24 ou superior. Integrações de anúncios, ATT e lembretes são executadas apenas nas plataformas móveis suportadas.

## Funcionalidades

- Splash durante a inicialização; welcome com permissões opcionais; introdução exibida antes da home, apenas até concluir o primeiro acesso.
- Navegação por `AppBarMain` e abas Simular, Histórico e Perfil.
- Renda, valor do veículo, entrada, ano de fabricação, zero km/seminovo/usado e prazos de 12 a 72 meses.
- Comparação por instituição com taxas do Banco Central, busca por banco e filtro de parcelas de até 30% da renda.
- Alternativa de taxa personalizada, inclusive taxa zero, quando a consulta estiver indisponível ou o usuário tiver uma cotação própria.
- Parcela pela Tabela Price, principal, juros totais, soma das parcelas e custo com entrada.
- Histórico persistente no dispositivo, detalhes e exclusão de simulações.
- Cadastro, login por e-mail/senha, recuperação de senha e edição de nome preparados para Firebase Authentication e Firestore.
- Três lembretes locais recorrentes: 9h, 14h e 19h, no fuso do dispositivo. Permissão solicitada após toque na welcome/perfil; desativação cancela os três agendamentos. Android usa alarmes inexatos: o sistema pode atrasar a entrega. Os lembretes são educativos; não anunciam variações bancárias que não foram consultadas.
- AdMob com banner e IDs oficiais de teste. UMP antes de solicitar anúncios; ATT opcional no iOS; preferências de anúncios no perfil quando aplicáveis. O banner usa requisições de anúncios não personalizados.

## Taxas e limites da estimativa

Consulta pública validada: `https://olinda.bcb.gov.br/olinda/servico/taxaJuros/versao/v2/odata/ConsultaUnificada`, com `codigoSegmento = 1` e `codigoModalidade = 401101` (pessoa física, aquisição de veículos, prefixado). O app seleciona o período mais recente retornado, mostra esse período e o horário da consulta. Não usa taxas bancárias inventadas como fallback. As taxas são consultadas pela internet e mantidas em memória até atualizar/reabrir o aplicativo.

São médias de operações realizadas, não propostas para o usuário. Taxas e aprovação variam por cliente e instituição; bancos de montadoras podem exigir uma marca/modelo específico. O BCB não fornece regras de aprovação por salário, ano ou condição do carro. Ano e condição ficam registrados na simulação, sem inventar critérios por banco. O limite de 30% é apenas uma referência de planejamento.

O cálculo considera primeira parcela em um mês e juros compostos mensais fixos. Não inclui IOF, seguros, tarifas, serviços ou outros custos e não calcula CET. “Total a contratar” é o principal sem despesas adicionais. O app não consulta CPF e não solicita nem contrata crédito.

Fonte: [Banco Central — taxas de juros](https://www.bcb.gov.br/estatisticas/txjuros).

## Habilitar Firebase quando o projeto estiver disponível

O app funciona sem Firebase, com modo visitante e histórico local. Nenhuma credencial fictícia é usada. Para habilitar contas:

1. Crie um projeto no console Firebase. Registre Android (`com.diogo.financia_auto`) e iOS (`com.diogo.financiaAuto`).
2. Habilite **Authentication > E-mail/senha** e crie o **Cloud Firestore**.
3. Aplique `firestore.rules` no console ou, com a CLI Firebase instalada/autenticada, execute `firebase deploy --only firestore:rules --project SEU_ID`. As regras restringem cada perfil e simulação ao UID autenticado.
4. Copie `config/firebase.example.json` para `config/firebase.android.json` ou `config/firebase.ios.json` e preencha os valores das configurações dos respectivos apps Firebase. Use o App ID específico de cada plataforma. Não coloque chaves de contas de serviço nesses arquivos.
5. Execute com a configuração correspondente:

```powershell
flutter run --dart-define-from-file=config/firebase.android.json
```

A inicialização usa `FirebaseOptions` em Dart; os recursos atuais (e-mail/senha e Firestore) não exigem arquivos nativos de serviços Google. Caso adicione Google Sign-In, Analytics, Messaging ou outros serviços, siga o fluxo FlutterFire e complete as configurações nativas desses produtos. Para web, registre um app web e configure os domínios autorizados.

O histórico de visitante e o de cada UID ficam separados. Entrar não envia automaticamente o histórico do visitante. Novas simulações salvas durante o login são persistidas localmente e enviadas ao Firestore; os registros remotos são carregados ao entrar. Falhas são informadas na interface; gravações locais permanecem disponíveis. SharedPreferences não é armazenamento criptografado. Antes de produção, defina política de privacidade, retenção e exclusão da conta/dados.

Estrutura Firestore:

```text
users/{uid}                         nome, e-mail, criação do perfil
users/{uid}/simulations/{id}        entradas e taxa da simulação
```

Documentação: [Firebase para Flutter](https://firebase.google.com/docs/flutter/setup).

## Habilitar anúncios reais

Os IDs atuais são **de teste** e não geram receita. Após criar a conta AdMob:

1. Troque o App ID em `android/app/src/main/AndroidManifest.xml` e `GADApplicationIdentifier` em `ios/Runner/Info.plist`.
2. Troque os IDs dos banners em `lib/services/ads_service.dart` e remova a indicação “anúncio de teste” de `ad_banner.dart` quando usar unidades reais.
3. Configure as mensagens de privacidade no AdMob para UMP, as URLs de privacidade e as declarações de dados das lojas. Revise os SKAdNetwork IDs conforme o SDK e parceiros usados; o Info.plist contém o identificador do Google.
4. Valide consentimento, ATT, exibição e rejeição de permissões em aparelhos reais antes de publicar.

Referências: [AdMob para Flutter](https://developers.google.com/admob/flutter/quick-start), [UMP](https://developers.google.com/admob/flutter/privacy), [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications).

## Organização e validação

```text
lib/color/        paleta padronizada
lib/models/       dados e cálculo financeiro
lib/pages/        welcome, introdução, simulador, resultado, histórico, perfil
lib/services/     taxas, persistência, Firebase, anúncios, notificações
lib/widgets/      glass cards, fundo, AppBarMain, banner
lib/utils/        formatação monetária e datas
test/             cálculo, consulta bancária, histórico e fluxos de tela
```

```powershell
flutter analyze
flutter test
flutter build apk --debug
```

A versão release ainda utiliza a assinatura de desenvolvimento padrão do projeto. Configure a chave de assinatura própria para publicar. Firebase, consentimento nativo, anúncios e entrega de notificações precisam de testes em dispositivos reais; os testes locais não substituem essa validação.
# financia-auto
