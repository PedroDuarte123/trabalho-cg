Trabalho dos alunos Pedro Duarte, Giovane Bahia, Gabriel de Andrade e Rodrigo Motta para a disciplina de Computação Gráfica 2026.1.

Fluxo básico no git: <br>
git checkout main - Muda para a branch main; <br>
git pull origin main - Puxa todas as mudanças da branch remota main para a branch main local; <br>
git checkout -b feat/nome_da_minha_branch - Cria uma nova branch com o nome "feat/nome_da_minha_branch"; <br>
git add CAMINHO_ARQUIVO - Prepara arquivo(s) que você modificou para o próximo commit;
git commit -m “MENSAGEM_COMMIT” - Registra as mudanças adicionadas; anteriormente com o git add, informando o autor, data, mensagem e o que foi mudado nos arquivos;<br>
git push origin feat_nome_da_minha_branch - Envia as mudanças dos commits realizados na branch local para a branch remota especificada;<br>
Se estiver tudo certo, abra um pull request na aba Pull Requests da sua branch para a main para mesclar as duas branches e atualizar a main com suas alterações.<br>



Boas práticas:<br>
1) Nomear a branch com o prefixo "feat/" para branches de novas funcionalidades, "fix/" para branches de correções e "chore/" para tarefas que não afetam o funcionamento do código(documentação, etc.); <br>
2) Utilizar mensagens claras nos commits de acordo com as suas alterações. Utilizar prefixo "feat:" para novas funcionalidades, "fix:" para correções e "chore: para alterações que não afetam funcionamento do código(documentação, etc)"<br>

Comandos úteis:<br>
git status - Exibe a branch atual e quais arquivos foram modificados;<br>
git branch - Exibe todas as branches do repositório;
