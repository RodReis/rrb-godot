ALTER TABLE "users" ADD COLUMN "queue_unlock_reason" text;--> statement-breakpoint
-- SPEC-085: quem já tem partida online no histórico (finished/aborted, a mesma definição de
-- GET /matches?mine=1) fica com a fila liberada; as demais contas seguem a regra nova.
UPDATE "users" SET "queue_unlock_reason" = 'history'
WHERE EXISTS (
  SELECT 1 FROM "match_players" mp
  JOIN "matches" m ON m."id" = mp."match_id"
  WHERE mp."user_id" = "users"."id" AND m."status" IN ('finished', 'aborted')
);
