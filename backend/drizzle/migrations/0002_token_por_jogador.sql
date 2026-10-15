ALTER TABLE "match_players" ADD COLUMN "token_hash" text;--> statement-breakpoint
UPDATE "match_players" SET "token_hash" = "matches"."token_hash" FROM "matches" WHERE "matches"."id" = "match_players"."match_id";--> statement-breakpoint
ALTER TABLE "match_players" ALTER COLUMN "token_hash" SET NOT NULL;--> statement-breakpoint
ALTER TABLE "matches" DROP COLUMN "token_hash";
