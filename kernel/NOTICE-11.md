# Porte privado QBX — lote 11

Derivado dos fontes instalados `qbx_core/server/{character_slots,character,document_items}.lua`. Licença MIT integral e autoria originais preservadas em LICENSE-QBX.

Fábricas/composição privadas e inativas. Slots usam Service estável e storage/lookup/logout internos; Ready é descritor, sem DDL automático. Callbacks/personagens/kit/prévias não são instalados no construtor. GetCharacterPreviews é serviço interno normalizado, nunca self-export. O evento legado usa exclusão com dono, não o export administrativo force.

Inventário e catálogo/configuração DK passam por portas PR; integração DK ainda sem equivalente localizado e não ligada. Este porte não emite documentos nem altera kit/JSON/renderer/loadscreen/tabelas/dados. Poll de inventário sem prazo/identidade, snapshot de slots antes da trava e retornos de escrita ignorados são comportamentos herdados catalogados, não liberados para ativação. Efeitos somente simulados nos testes; detalhes em `.planning/migration/LOTE-11.md`.
