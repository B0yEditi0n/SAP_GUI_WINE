H2 Detalhes criação do Projeto

Caso queira especifcar o diretório Wine a ser instalado rode o comando,
por padrão ele criará o prefixo no `/home/user/.wine`
```
export SAPGUI_WINEPREFIX="caminho ser instalado"
```

#3 Observação Importante
- ao instalar o SAP escolha uma pasta sem espaços evita dores de cabeça ao criar atalhos de lançador.
por padrão defino a pasta `C:\SAP\` todavia não dá pra forçar a instalação nesse diretório.
- é comum a instalação dar erros o wine falha ao instalar os pacotes de C++ portanto sua instalação é feita antes da chamada de instalação do sap portanto não se preocupe.
- Caso aconteça o Bug do "Ghost window", onde uma janela do sap apos ser alternada ou minimizada deixa um rastro de borda soubre outra aplicação tente isso (no meu caso o bug aconteceu no cinnamon).
"Configurações do Sistema" -> "Efeitos" "Desative todos os efeitos"

