CREATE TYPE "public"."match_status" AS ENUM('assigned', 'running', 'finished', 'aborted');--> statement-breakpoint
CREATE TYPE "public"."ticket_status" AS ENUM('waiting', 'matched', 'cancelled', 'expired');--> statement-breakpoint
CREATE TABLE "match_players" (
	"match_id" uuid NOT NULL,
	"user_id" uuid NOT NULL,
	"hero_id" text,
	"kills" integer DEFAULT 0 NOT NULL,
	"deaths" integer DEFAULT 0 NOT NULL,
	"final_level" integer DEFAULT 0 NOT NULL,
	"damage_dealt" double precision DEFAULT 0 NOT NULL,
	"damage_taken" double precision DEFAULT 0 NOT NULL,
	"monsters_killed" integer DEFAULT 0 NOT NULL,
	"chests_opened" integer DEFAULT 0 NOT NULL,
	"boss_kill" boolean DEFAULT false NOT NULL,
	"set_active" text,
	"level_at_phase1_end" integer,
	"avg_ping_ms" integer,
	CONSTRAINT "match_players_match_id_user_id_pk" PRIMARY KEY("match_id","user_id")
);
--> statement-breakpoint
CREATE TABLE "matches" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"status" "match_status" DEFAULT 'assigned' NOT NULL,
	"server_host" text NOT NULL,
	"server_port" integer NOT NULL,
	"token_hash" text NOT NULL,
	"seed" integer NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"started_at" timestamp with time zone,
	"last_heartbeat_at" timestamp with time zone,
	"ended_at" timestamp with time zone,
	"winner_user_id" uuid,
	"end_reason" text,
	"duration_s" integer
);
--> statement-breakpoint
CREATE TABLE "queue_tickets" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"seq" serial NOT NULL,
	"user_id" uuid NOT NULL,
	"status" "ticket_status" DEFAULT 'waiting' NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"last_seen_at" timestamp with time zone DEFAULT now() NOT NULL,
	"match_id" uuid
);
--> statement-breakpoint
ALTER TABLE "match_players" ADD CONSTRAINT "match_players_match_id_matches_id_fk" FOREIGN KEY ("match_id") REFERENCES "public"."matches"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "match_players" ADD CONSTRAINT "match_players_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "matches" ADD CONSTRAINT "matches_winner_user_id_users_id_fk" FOREIGN KEY ("winner_user_id") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "queue_tickets" ADD CONSTRAINT "queue_tickets_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "queue_tickets" ADD CONSTRAINT "queue_tickets_match_id_matches_id_fk" FOREIGN KEY ("match_id") REFERENCES "public"."matches"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "match_players_user_idx" ON "match_players" USING btree ("user_id");--> statement-breakpoint
CREATE UNIQUE INDEX "queue_tickets_one_waiting_per_user" ON "queue_tickets" USING btree ("user_id") WHERE "queue_tickets"."status" = 'waiting';--> statement-breakpoint
CREATE INDEX "queue_tickets_waiting_idx" ON "queue_tickets" USING btree ("seq") WHERE "queue_tickets"."status" = 'waiting';