# Trabalho de Computação Gráfica (2026.1)

Trabalho dos alunos **Pedro Duarte**, **Giovane Bahia**, **Gabriel de Andrade** e **Rodrigo Motta** para a disciplina de **Computação Gráfica 2026.1**.

## Fluxo básico no Git

1. `git checkout main` — muda para a branch `main`.
2. `git pull origin main` — puxa as mudanças da branch remota `main` para a `main` local.
3. `git checkout -b feat/nome_da_minha_branch` — cria uma nova branch (ex.: `feat/minha-feature`).
4. `git add CAMINHO_ARQUIVO` — prepara o(s) arquivo(s) modificados para o commit.
5. `git commit -m "MENSAGEM_COMMIT"` — registra as mudanças adicionadas no `git add`.
6. `git push origin feat/nome_da_minha_branch` — envia os commits da branch local para a branch remota.
7. Se estiver tudo certo, abra um **Pull Request** da sua branch para a `main` para mesclar as alterações.

### Exemplo (sequência típica)

```bash
git checkout main
git pull origin main

git checkout -b feat/nome_da_minha_branch
git add CAMINHO_ARQUIVO
git commit -m "feat: minha alteração"
git push origin feat/nome_da_minha_branch
```

## Boas práticas

1. Nomear a branch com o prefixo:
	- `feat/` para novas funcionalidades;
	- `fix/` para correções;
	- `chore/` para tarefas que não afetam o funcionamento do código (documentação, etc.).
2. Utilizar mensagens claras nos commits, com prefixos:
	- `feat:` para novas funcionalidades;
	- `fix:` para correções;
	- `chore:` para alterações que não afetam o funcionamento do código (documentação, etc.).

## Comandos úteis

- `git status` — exibe a branch atual e quais arquivos foram modificados.
- `git branch` — exibe todas as branches do repositório.
