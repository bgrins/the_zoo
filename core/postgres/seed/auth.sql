--
-- PostgreSQL database dump
--

\restrict Y0xsDm5hKncALIuB3fMqbdtQygOGz6yDJxm4SzgjriQaeImhjAQe7HJX9NMbBRZ

-- Dumped from database version 16.10
-- Dumped by pg_dump version 16.10

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: auth_user
--

CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_updated_at_column() OWNER TO auth_user;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: hydra_client; Type: TABLE; Schema: public; Owner: auth_user
--

CREATE TABLE public.hydra_client (
    id character varying(255) NOT NULL,
    client_name text NOT NULL,
    client_secret text NOT NULL,
    scope text NOT NULL,
    owner text NOT NULL,
    policy_uri text NOT NULL,
    tos_uri text NOT NULL,
    client_uri text NOT NULL,
    logo_uri text NOT NULL,
    client_secret_expires_at integer DEFAULT 0 NOT NULL,
    sector_identifier_uri text NOT NULL,
    jwks text NOT NULL,
    jwks_uri text NOT NULL,
    token_endpoint_auth_method character varying(25) DEFAULT ''::character varying NOT NULL,
    request_object_signing_alg character varying(10) DEFAULT ''::character varying NOT NULL,
    userinfo_signed_response_alg character varying(10) DEFAULT ''::character varying NOT NULL,
    subject_type character varying(15) DEFAULT ''::character varying NOT NULL,
    pk_deprecated integer NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    frontchannel_logout_uri text DEFAULT ''::text NOT NULL,
    frontchannel_logout_session_required boolean DEFAULT false NOT NULL,
    backchannel_logout_uri text DEFAULT ''::text NOT NULL,
    backchannel_logout_session_required boolean DEFAULT false NOT NULL,
    metadata text NOT NULL,
    token_endpoint_auth_signing_alg character varying(10) DEFAULT ''::character varying NOT NULL,
    authorization_code_grant_access_token_lifespan bigint,
    authorization_code_grant_id_token_lifespan bigint,
    authorization_code_grant_refresh_token_lifespan bigint,
    client_credentials_grant_access_token_lifespan bigint,
    implicit_grant_access_token_lifespan bigint,
    implicit_grant_id_token_lifespan bigint,
    jwt_bearer_grant_access_token_lifespan bigint,
    password_grant_access_token_lifespan bigint,
    password_grant_refresh_token_lifespan bigint,
    refresh_token_grant_id_token_lifespan bigint,
    refresh_token_grant_access_token_lifespan bigint,
    refresh_token_grant_refresh_token_lifespan bigint,
    pk uuid,
    registration_access_token_signature character varying(128) DEFAULT ''::character varying NOT NULL,
    nid uuid NOT NULL,
    redirect_uris jsonb NOT NULL,
    grant_types jsonb NOT NULL,
    response_types jsonb NOT NULL,
    audience jsonb NOT NULL,
    allowed_cors_origins jsonb NOT NULL,
    contacts jsonb NOT NULL,
    request_uris jsonb NOT NULL,
    post_logout_redirect_uris jsonb DEFAULT '[]'::jsonb NOT NULL,
    access_token_strategy character varying(10) DEFAULT ''::character varying NOT NULL,
    skip_consent boolean DEFAULT false NOT NULL,
    skip_logout_consent boolean
);


ALTER TABLE public.hydra_client OWNER TO auth_user;

--
-- Name: hydra_client_pk_seq; Type: SEQUENCE; Schema: public; Owner: auth_user
--

CREATE SEQUENCE public.hydra_client_pk_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.hydra_client_pk_seq OWNER TO auth_user;

--
-- Name: hydra_client_pk_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: auth_user
--

ALTER SEQUENCE public.hydra_client_pk_seq OWNED BY public.hydra_client.pk_deprecated;


--
-- Name: hydra_jwk; Type: TABLE; Schema: public; Owner: auth_user
--

CREATE TABLE public.hydra_jwk (
    sid character varying(255) NOT NULL,
    kid character varying(255) NOT NULL,
    version integer DEFAULT 0 NOT NULL,
    keydata text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    pk_deprecated integer NOT NULL,
    pk uuid NOT NULL,
    nid uuid NOT NULL
);


ALTER TABLE public.hydra_jwk OWNER TO auth_user;

--
-- Name: hydra_jwk_pk_seq; Type: SEQUENCE; Schema: public; Owner: auth_user
--

CREATE SEQUENCE public.hydra_jwk_pk_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.hydra_jwk_pk_seq OWNER TO auth_user;

--
-- Name: hydra_jwk_pk_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: auth_user
--

ALTER SEQUENCE public.hydra_jwk_pk_seq OWNED BY public.hydra_jwk.pk_deprecated;


--
-- Name: hydra_oauth2_access; Type: TABLE; Schema: public; Owner: auth_user
--

CREATE TABLE public.hydra_oauth2_access (
    signature character varying(255) NOT NULL,
    request_id character varying(40) NOT NULL,
    requested_at timestamp without time zone DEFAULT now() NOT NULL,
    client_id character varying(255) NOT NULL,
    scope text NOT NULL,
    granted_scope text NOT NULL,
    form_data text NOT NULL,
    session_data text NOT NULL,
    subject character varying(255) DEFAULT ''::character varying NOT NULL,
    active boolean DEFAULT true NOT NULL,
    requested_audience text DEFAULT ''::text,
    granted_audience text DEFAULT ''::text,
    challenge_id character varying(40),
    nid uuid NOT NULL
);


ALTER TABLE public.hydra_oauth2_access OWNER TO auth_user;

--
-- Name: hydra_oauth2_authentication_session; Type: TABLE; Schema: public; Owner: auth_user
--

CREATE TABLE public.hydra_oauth2_authentication_session (
    id character varying(40) NOT NULL,
    authenticated_at timestamp without time zone,
    subject character varying(255) NOT NULL,
    remember boolean DEFAULT false NOT NULL,
    nid uuid NOT NULL,
    identity_provider_session_id character varying(40)
);


ALTER TABLE public.hydra_oauth2_authentication_session OWNER TO auth_user;

--
-- Name: hydra_oauth2_code; Type: TABLE; Schema: public; Owner: auth_user
--

CREATE TABLE public.hydra_oauth2_code (
    signature character varying(255) NOT NULL,
    request_id character varying(40) NOT NULL,
    requested_at timestamp without time zone DEFAULT now() NOT NULL,
    client_id character varying(255) NOT NULL,
    scope text NOT NULL,
    granted_scope text NOT NULL,
    form_data text NOT NULL,
    session_data text NOT NULL,
    subject character varying(255) DEFAULT ''::character varying NOT NULL,
    active boolean DEFAULT true NOT NULL,
    requested_audience text DEFAULT ''::text,
    granted_audience text DEFAULT ''::text,
    challenge_id character varying(40),
    nid uuid NOT NULL
);


ALTER TABLE public.hydra_oauth2_code OWNER TO auth_user;

--
-- Name: hydra_oauth2_flow; Type: TABLE; Schema: public; Owner: auth_user
--

CREATE TABLE public.hydra_oauth2_flow (
    login_challenge character varying(40) NOT NULL,
    login_verifier character varying(40) NOT NULL,
    login_csrf character varying(40) NOT NULL,
    subject character varying(255) NOT NULL,
    request_url text NOT NULL,
    login_skip boolean NOT NULL,
    client_id character varying(255) NOT NULL,
    requested_at timestamp without time zone DEFAULT now() NOT NULL,
    login_initialized_at timestamp without time zone,
    oidc_context jsonb DEFAULT '{}'::jsonb NOT NULL,
    login_session_id character varying(40),
    state integer NOT NULL,
    login_remember boolean DEFAULT false NOT NULL,
    login_remember_for integer NOT NULL,
    login_error text,
    acr text DEFAULT ''::text NOT NULL,
    login_authenticated_at timestamp without time zone,
    login_was_used boolean DEFAULT false NOT NULL,
    forced_subject_identifier character varying(255) DEFAULT ''::character varying NOT NULL,
    context jsonb DEFAULT '{}'::jsonb NOT NULL,
    consent_challenge_id character varying(40),
    consent_skip boolean DEFAULT false NOT NULL,
    consent_verifier character varying(40),
    consent_csrf character varying(40),
    consent_remember boolean DEFAULT false NOT NULL,
    consent_remember_for integer,
    consent_handled_at timestamp without time zone,
    consent_error text,
    session_access_token jsonb DEFAULT '{}'::jsonb NOT NULL,
    session_id_token jsonb DEFAULT '{}'::jsonb NOT NULL,
    consent_was_used boolean DEFAULT false NOT NULL,
    nid uuid NOT NULL,
    requested_scope jsonb NOT NULL,
    requested_at_audience jsonb DEFAULT '[]'::jsonb,
    amr jsonb DEFAULT '[]'::jsonb,
    granted_scope jsonb,
    granted_at_audience jsonb DEFAULT '[]'::jsonb,
    login_extend_session_lifespan boolean DEFAULT false NOT NULL,
    identity_provider_session_id character varying(40),
    CONSTRAINT hydra_oauth2_flow_check CHECK (((state = 128) OR (state = 129) OR (state = 1) OR ((state = 2) AND ((login_remember IS NOT NULL) AND (login_remember_for IS NOT NULL) AND (login_error IS NOT NULL) AND (acr IS NOT NULL) AND (login_was_used IS NOT NULL) AND (context IS NOT NULL) AND (amr IS NOT NULL))) OR ((state = 3) AND ((login_remember IS NOT NULL) AND (login_remember_for IS NOT NULL) AND (login_error IS NOT NULL) AND (acr IS NOT NULL) AND (login_was_used IS NOT NULL) AND (context IS NOT NULL) AND (amr IS NOT NULL))) OR ((state = 4) AND ((login_remember IS NOT NULL) AND (login_remember_for IS NOT NULL) AND (login_error IS NOT NULL) AND (acr IS NOT NULL) AND (login_was_used IS NOT NULL) AND (context IS NOT NULL) AND (amr IS NOT NULL) AND (consent_challenge_id IS NOT NULL) AND (consent_verifier IS NOT NULL) AND (consent_skip IS NOT NULL) AND (consent_csrf IS NOT NULL))) OR ((state = 5) AND ((login_remember IS NOT NULL) AND (login_remember_for IS NOT NULL) AND (login_error IS NOT NULL) AND (acr IS NOT NULL) AND (login_was_used IS NOT NULL) AND (context IS NOT NULL) AND (amr IS NOT NULL) AND (consent_challenge_id IS NOT NULL) AND (consent_verifier IS NOT NULL) AND (consent_skip IS NOT NULL) AND (consent_csrf IS NOT NULL))) OR ((state = 6) AND ((login_remember IS NOT NULL) AND (login_remember_for IS NOT NULL) AND (login_error IS NOT NULL) AND (acr IS NOT NULL) AND (login_was_used IS NOT NULL) AND (context IS NOT NULL) AND (amr IS NOT NULL) AND (consent_challenge_id IS NOT NULL) AND (consent_verifier IS NOT NULL) AND (consent_skip IS NOT NULL) AND (consent_csrf IS NOT NULL) AND (granted_scope IS NOT NULL) AND (consent_remember IS NOT NULL) AND (consent_remember_for IS NOT NULL) AND (consent_error IS NOT NULL) AND (session_access_token IS NOT NULL) AND (session_id_token IS NOT NULL) AND (consent_was_used IS NOT NULL)))))
);


ALTER TABLE public.hydra_oauth2_flow OWNER TO auth_user;

--
-- Name: hydra_oauth2_jti_blacklist; Type: TABLE; Schema: public; Owner: auth_user
--

CREATE TABLE public.hydra_oauth2_jti_blacklist (
    signature character varying(64) NOT NULL,
    expires_at timestamp without time zone DEFAULT now() NOT NULL,
    nid uuid NOT NULL
);


ALTER TABLE public.hydra_oauth2_jti_blacklist OWNER TO auth_user;

--
-- Name: hydra_oauth2_logout_request; Type: TABLE; Schema: public; Owner: auth_user
--

CREATE TABLE public.hydra_oauth2_logout_request (
    challenge character varying(36) NOT NULL,
    verifier character varying(36) NOT NULL,
    subject character varying(255) NOT NULL,
    sid character varying(36) NOT NULL,
    client_id character varying(255),
    request_url text NOT NULL,
    redir_url text NOT NULL,
    was_used boolean DEFAULT false NOT NULL,
    accepted boolean DEFAULT false NOT NULL,
    rejected boolean DEFAULT false NOT NULL,
    rp_initiated boolean DEFAULT false NOT NULL,
    nid uuid NOT NULL
);


ALTER TABLE public.hydra_oauth2_logout_request OWNER TO auth_user;

--
-- Name: hydra_oauth2_obfuscated_authentication_session; Type: TABLE; Schema: public; Owner: auth_user
--

CREATE TABLE public.hydra_oauth2_obfuscated_authentication_session (
    subject character varying(255) NOT NULL,
    client_id character varying(255) NOT NULL,
    subject_obfuscated character varying(255) NOT NULL,
    nid uuid NOT NULL
);


ALTER TABLE public.hydra_oauth2_obfuscated_authentication_session OWNER TO auth_user;

--
-- Name: hydra_oauth2_oidc; Type: TABLE; Schema: public; Owner: auth_user
--

CREATE TABLE public.hydra_oauth2_oidc (
    signature character varying(255) NOT NULL,
    request_id character varying(40) NOT NULL,
    requested_at timestamp without time zone DEFAULT now() NOT NULL,
    client_id character varying(255) NOT NULL,
    scope text NOT NULL,
    granted_scope text NOT NULL,
    form_data text NOT NULL,
    session_data text NOT NULL,
    subject character varying(255) DEFAULT ''::character varying NOT NULL,
    active boolean DEFAULT true NOT NULL,
    requested_audience text DEFAULT ''::text,
    granted_audience text DEFAULT ''::text,
    challenge_id character varying(40),
    nid uuid NOT NULL
);


ALTER TABLE public.hydra_oauth2_oidc OWNER TO auth_user;

--
-- Name: hydra_oauth2_pkce; Type: TABLE; Schema: public; Owner: auth_user
--

CREATE TABLE public.hydra_oauth2_pkce (
    signature character varying(255) NOT NULL,
    request_id character varying(40) NOT NULL,
    requested_at timestamp without time zone DEFAULT now() NOT NULL,
    client_id character varying(255) NOT NULL,
    scope text NOT NULL,
    granted_scope text NOT NULL,
    form_data text NOT NULL,
    session_data text NOT NULL,
    subject character varying(255) NOT NULL,
    active boolean DEFAULT true NOT NULL,
    requested_audience text DEFAULT ''::text,
    granted_audience text DEFAULT ''::text,
    challenge_id character varying(40),
    nid uuid NOT NULL
);


ALTER TABLE public.hydra_oauth2_pkce OWNER TO auth_user;

--
-- Name: hydra_oauth2_refresh; Type: TABLE; Schema: public; Owner: auth_user
--

CREATE TABLE public.hydra_oauth2_refresh (
    signature character varying(255) NOT NULL,
    request_id character varying(40) NOT NULL,
    requested_at timestamp without time zone DEFAULT now() NOT NULL,
    client_id character varying(255) NOT NULL,
    scope text NOT NULL,
    granted_scope text NOT NULL,
    form_data text NOT NULL,
    session_data text NOT NULL,
    subject character varying(255) DEFAULT ''::character varying NOT NULL,
    active boolean DEFAULT true NOT NULL,
    requested_audience text DEFAULT ''::text,
    granted_audience text DEFAULT ''::text,
    challenge_id character varying(40),
    nid uuid NOT NULL
);


ALTER TABLE public.hydra_oauth2_refresh OWNER TO auth_user;

--
-- Name: hydra_oauth2_trusted_jwt_bearer_issuer; Type: TABLE; Schema: public; Owner: auth_user
--

CREATE TABLE public.hydra_oauth2_trusted_jwt_bearer_issuer (
    id uuid NOT NULL,
    issuer character varying(255) NOT NULL,
    subject character varying(255) NOT NULL,
    scope text NOT NULL,
    key_set character varying(255) NOT NULL,
    key_id character varying(255) NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    expires_at timestamp without time zone DEFAULT now() NOT NULL,
    nid uuid NOT NULL,
    allow_any_subject boolean DEFAULT false NOT NULL
);


ALTER TABLE public.hydra_oauth2_trusted_jwt_bearer_issuer OWNER TO auth_user;

--
-- Name: migrations; Type: TABLE; Schema: public; Owner: auth_user
--

CREATE TABLE public.migrations (
    id integer NOT NULL,
    filename character varying(255) NOT NULL,
    executed_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.migrations OWNER TO auth_user;

--
-- Name: migrations_id_seq; Type: SEQUENCE; Schema: public; Owner: auth_user
--

CREATE SEQUENCE public.migrations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.migrations_id_seq OWNER TO auth_user;

--
-- Name: migrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: auth_user
--

ALTER SEQUENCE public.migrations_id_seq OWNED BY public.migrations.id;


--
-- Name: networks; Type: TABLE; Schema: public; Owner: auth_user
--

CREATE TABLE public.networks (
    id uuid NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.networks OWNER TO auth_user;

--
-- Name: schema_migration; Type: TABLE; Schema: public; Owner: auth_user
--

CREATE TABLE public.schema_migration (
    version character varying(48) NOT NULL,
    version_self integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.schema_migration OWNER TO auth_user;

--
-- Name: users; Type: TABLE; Schema: public; Owner: auth_user
--

CREATE TABLE public.users (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    username character varying(255) NOT NULL,
    email character varying(255) NOT NULL,
    password_hash character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.users OWNER TO auth_user;

--
-- Name: hydra_client pk_deprecated; Type: DEFAULT; Schema: public; Owner: auth_user
--

ALTER TABLE ONLY public.hydra_client ALTER COLUMN pk_deprecated SET DEFAULT nextval('public.hydra_client_pk_seq'::regclass);


--
-- Name: hydra_jwk pk_deprecated; Type: DEFAULT; Schema: public; Owner: auth_user
--

ALTER TABLE ONLY public.hydra_jwk ALTER COLUMN pk_deprecated SET DEFAULT nextval('public.hydra_jwk_pk_seq'::regclass);


--
-- Name: migrations id; Type: DEFAULT; Schema: public; Owner: auth_user
--

ALTER TABLE ONLY public.migrations ALTER COLUMN id SET DEFAULT nextval('public.migrations_id_seq'::regclass);


--
-- Data for Name: hydra_client; Type: TABLE DATA; Schema: public; Owner: auth_user
--

COPY public.hydra_client (id, client_name, client_secret, scope, owner, policy_uri, tos_uri, client_uri, logo_uri, client_secret_expires_at, sector_identifier_uri, jwks, jwks_uri, token_endpoint_auth_method, request_object_signing_alg, userinfo_signed_response_alg, subject_type, pk_deprecated, created_at, updated_at, frontchannel_logout_uri, frontchannel_logout_session_required, backchannel_logout_uri, backchannel_logout_session_required, metadata, token_endpoint_auth_signing_alg, authorization_code_grant_access_token_lifespan, authorization_code_grant_id_token_lifespan, authorization_code_grant_refresh_token_lifespan, client_credentials_grant_access_token_lifespan, implicit_grant_access_token_lifespan, implicit_grant_id_token_lifespan, jwt_bearer_grant_access_token_lifespan, password_grant_access_token_lifespan, password_grant_refresh_token_lifespan, refresh_token_grant_id_token_lifespan, refresh_token_grant_access_token_lifespan, refresh_token_grant_refresh_token_lifespan, pk, registration_access_token_signature, nid, redirect_uris, grant_types, response_types, audience, allowed_cors_origins, contacts, request_uris, post_logout_redirect_uris, access_token_strategy, skip_consent, skip_logout_consent) FROM stdin;
zoo-misc-app	Zoo Misc Application	$pbkdf2-sha256$i=25000,l=32$A/shIgocAKQ6hT5BIzLh1Q$CGtlBHGhgK4tF2ztedb8Tp6uNVkslB/rpz99AgscNyo	openid offline profile email						0		{}		client_secret_basic		none	public	0	2025-07-29 04:28:22	2025-10-09 21:45:15.378867		f		f	{}		\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N		e95bff79-a564-4963-9f57-c8d76631d8c7	["https://misc.zoo/oauth/callback", "http://misc.zoo/oauth/callback"]	["authorization_code", "refresh_token"]	["code"]	[]	[]	[]	[]	["https://misc.zoo/", "http://misc.zoo/"]		f	\N
gitea	Gitea	$pbkdf2-sha256$i=25000,l=32$pcBcp8r1WBk72BpE3PowNg$AemqoSx6rYziFJZeEk0opFnB+2xh4t9+FHNQbCa0Vp0	openid offline profile email						0		{}		client_secret_basic		none	public	0	2025-07-29 04:28:22	2025-10-09 21:45:15.471334		f		f	{}		\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N		e95bff79-a564-4963-9f57-c8d76631d8c7	["http://gitea.zoo/user/oauth2/auth.zoo/callback"]	["authorization_code", "refresh_token"]	["code"]	[]	[]	[]	[]	["http://gitea.zoo/"]		f	\N
miniflux	Miniflux RSS Reader	$pbkdf2-sha256$i=25000,l=32$bdX8e9sYwrA1FFQ8nIUknQ$hBVOFcopvDQ0yTbz674HNu5R41BOt6yX0t7VhHQGMjs	openid offline profile email						0		{}		client_secret_basic		none	public	0	2025-07-29 04:28:22	2025-10-09 21:45:15.552195		f		f	{}		\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N		e95bff79-a564-4963-9f57-c8d76631d8c7	["http://miniflux.zoo/oauth2/oidc/callback"]	["authorization_code", "refresh_token"]	["code"]	[]	[]	[]	[]	["http://miniflux.zoo/"]		f	\N
planka	Planka Project Management	$pbkdf2-sha256$i=25000,l=32$Xb5Su2VK4l6WXLol5lAlaQ$CmfGXAxF2YsJpvgoxfpv9oGse/Dk79c2kI0rPk6zY6U	openid offline profile email						0		{}		client_secret_basic		none	public	0	2025-07-29 04:28:22	2025-10-09 21:45:15.634379		f		f	{}		\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N		e95bff79-a564-4963-9f57-c8d76631d8c7	["http://planka.zoo/oidc-callback", "https://planka.zoo/oidc-callback"]	["authorization_code", "refresh_token"]	["code"]	[]	[]	[]	[]	["http://planka.zoo/", "https://planka.zoo/"]		f	\N
\.


--
-- Data for Name: hydra_jwk; Type: TABLE DATA; Schema: public; Owner: auth_user
--

COPY public.hydra_jwk (sid, kid, version, keydata, created_at, pk_deprecated, pk, nid) FROM stdin;
hydra.openid.id-token	d81f8472-2e20-4c8d-a512-cbc138d0aa14	0	c4SClCH8ylutNPGqMHydnLWlpxiMIx9-KJTUus5_7HBqGtedbgbFdMGCx4VplOW-aUJ96an8SYgwjuagfTOMZnYNhHYpWim9MThlvW-EbKV08hV3ZdDujsMU7VVXe5hFT2-T5hiDeUjgr3OiRk0840ZqcF0yyy5H7ZFPsGzBFues7kiT_CU8x2CGR0SPiOzbtZFpkMyn7T3UKqLXILLGKt5opIL7SLgGNPKaJNdHL-zeMwoWAeoSFNJo-L-_uvmEwqCk57BMCcZZoAbT4oBP8PS8BaoCaptrEcxwT-vFLsM4yOUqGZCTA6ze_Gd0EpPrQFX64tnacXQOkiFyixQKJP25Cx20KFdgmklBPbcE50A73XVcKlrDIDd2u4Xh0XcCwk_V05ArbP5LBXb3cKIm0O5Uut0ujz-J8dazsosTwqrR9cv6dVfZ_mbZ2zdKU4gQVr3WuURcRjVxI9BEmhcxsECSSPgBzmtfyW8Q3B0DjkTp7b07QTG0XZGoOlyaw1e5qHghCHIy_jaC2onrla-m9ELOxJ-TBp7HcxhyNONqDBwLrl0qoKhSxnssEvu5_A4P2HueaHRDi0uYNeuHcRVUbGWZ_J5W0EEB5doXF3zuF0cS9VcoO-uuM08xpph5KG3JD_PLqhWdPeAd85Kgor97OAkZc8bjF9f3q9JfVUR-a--h5QiM1gdPshdHHm7qkQpwVXjdNVo8ukYZwCfoBYcp_s9m3wTAuG3yWQvMVDrxDyaOwDS4M0qx-Slz0TYJG3-Vvkv61bW0MhFACvWLLwElXBvvAa5JpxtmEL61WqHsq_8-JJyRuNGGviwgJKQLEgzF-W8mXRfonsKKUJWGi1Men1Z1F0wqXtZ074pqVs2WoZEfLquHlOk-TlyWxOKJIPFBv6XaJ6_5XfzdQsW3t0CTZ293enPpliKXyssDI04VYGoX21JjZ9ot2oD0O-p2ZDIION_csEoc-LuhDq7FLqh9UBX2dv0LRrCIsWgpmrMY0nnH0F5PQ3_w8uiUuGC8-FAL93aVYDZyoZVjiFymuImtyzwHAb11tCkpSId4VFQ96b9oIxXZhJf6OItnbzGvbadvaXwtvoNRIcz8N5UaZn9SyWFxvAwo79-GaDgYK-qFyKU7-6d5JNp2vSnMM-Z3bC2Ymn-gaXRRetAxEBK1YlL6iiQFLBMUO2e0K7d0-7D4CsA8hk2iOz5fwdyYIyUUILSGrBHh7PUlcxdLthr305AEAfmICZBUv7yqYboDxH6F0ExM_26m1UyQiY5Qi9VnO7PHu3mnsomZ-vx4Y3LjPX7msET78dJ2kKxXLZ8Lx46QYcC5SiO2wqebl58SSU3_ZgCgAp3v2FJpYIPK9DwZuQFLlhb8-WZShRXhbQHVNUoE8SqodbxusdHe0z6BU7J0-YgTjrJj7U9UpgPyzeoLPIJ-E6Lr7lgxzG9183p4moQbhpX2HvuoEYbF60GRiuoyTQw-020FyWCIBXgAmASy_eUIbTjH2G3O7n7WxufiuxNnjfIqy3Ug-uEg8n7Foi5Ao9RE-yUzCNHI1tiEAYDTTFPPXsiT4-nXLSxyOGPlrM9xnoP2wK_bIzuxR927f-77D3yNgcJOzU5ixLxOnHYyZGyOqiWrJBDjsiLGr8GAm0yDdSS7hupsBYQI1O1Vfe6kg6JbVoYQSlFKmAQmHcTzSy4qhAet96dN5v8eLUz21XRGMBQmOiihucilPoswe5t-fvHiziJ-qQI8BlPqizWYTato4jGhptl6FZpp0gwA7Si-FU_pg41IyEv8JoB24_1C4f1QPAWJLST_VBm3V-JmUcp5mpU2f5Xclj5PUeiehH5jt3dGgYewTzqMEOSoIvy3jYGJa7A-1F7ZSkzhwAwNP_EdflULDVvJbaF_qXewny6IIX3x1eN-iXElCRtoZKtbxucHP7GcwGtvGsmc-iTP06uqrr4K0S8RpxGAwSr-WqHkrxyeVEjGfc3R5l8peJ4HPLSlkwHr7zTPYNyau58Dqbvr2wK7wFHEQnsC68g22GxaCykqloy0-Q57-5qDi4mABlWGDR0ka9NZXmosML6hiwqfobOsQBOL8cF7WmDpdPUWyVd01IAbCUYFQbR-ILW3U9GD4UGK53ty42NzpPihVj551mUjKmE8yNCP5BEBCmlYxlQiLqNorbgxtog2Q4VugE-4xz0Sa16I3xt-270v-WWhjr58NsHKD6cdaPZNB7HW8JjVY4nwNyUisbOItfwYKuAr3owB2Ia2gQF28nFKj7Ntlb5-gk5Dy_ZpkCBda7RQHCEgGmTBM7wo1u95PCiFQERIVHBdulxYUKOUN_F7SoFz4hgTKn-JiLd5OJ6MmpbPu83O9C0Jz4e5ezBHPOjA1Lc2ZeGWuVTpeejbjXX43Ql8m3whQa8ru9IE7sg2FNKyKIj7cykFZQkroJDhFhULjD47p4-i2GzjZSnSjNcC5TuMTwbAP0iWdzWh47lEoQbvFWNTRqjU7OoJLtqAMRKxBJxz260PQ2DixvdKBRd3DUwAx811TABBwMKLxUvl3K5NQpx8YcENEOGgi59zeQ7LHTVi7qO1yfGfpbQgkzHI_NqUVIUBcFUK419_tPg_WfHVK1OD9RhJjjcfKtaT3dftA59fdJnKLyZRDjo_nmIZLYVMFSsG-uxemZtIbRd7Aok76TCf8xSZW-54eCSz5TY8weOhdWgNO3jc-irjtYbuZaIRbCMfvF4_eewlHLydrOzxLrhvgNJOk8hPguDl35VmCdp4vvt45w8u5a63GRkfikX2jfxB_R6cwDs4sEchI3oBZ_t29XvvaN9br0eJnybUUpL7i0j3xdJD6FdBir9UGeenZ4PrtAoGdg0LaWL0Ai_L8llBOO29nrpChCc84oX9zSlkABcauQ4bdqNAorZGp4Fe0P190jtNkmmVRAq9_gUrLVdLeocVt4XydBlSwm7amrmjBo1NhfQCBuLvCfx8ujR_j8HkRv6w--_ouMjbWduIVcUvhPK7XNWE4ueQkpJ543tL71B5bASuCGkF2C1WhwchlNfhVEz3sgjY-328QxmYa3lKQYFcGJtLIJ4So1cBsAgMBVTnOXDl9J5y7ysZ2j5wFjvG8mfeL_pzdUm6Xl-IHHwnB-zCsC3DpCp6WUydgQZDjdoCKO4wtqral5DpZwfN7_viHBKE3F3HyWrpqPoy0iEqhUWVKeHDJULsQNLczyIYyE3hHpG2JNwxr9xa1QL_aPrdJaPi_M1N8fFUnTlBlTh3UlGaJoTq6R-b_W1mFUa--G4vPB4HCJhEuhPWGzXC_Dkl0kZ5cCNtkU5o62Mhx60TUKzvQH_fnwccqy7-jdGhWQ4mnlmsOhgYWbfavUmlqDbWTM3OLaGIEBgU6J9XnY9RWcFalR9wYrMdhDjfjBVoUTfg1CmCPse6f5hRpIP4NUsFnqdCLQSsuP6eudG5m8JDjAXFHrBrWunx19-ELNzAwjLT9bdGXRHg4BfQ1baPt30FStF_zRq6hAHiNFcIHM7Co3f8y_GbnGTBsBjZPUVhokQXCQ3LY-Ie85ab7QYPHs4lSM9j7yUp02gCG26HLiN4MfS5erR_jEcJKSmgXTNr1lfvlr8c62dt-p97lxQEzSyQMuJsc2R9Iysx5PGfBJdRmM2RvG8GHkrGhRffTvpgaZAOvbllcUq9ICj66myjiFX_b3YNEbBsxvto3sdNUxa-bbjttTRB5vszgl9Y_mArDkaRp_GjmC9RFefvfxoylOzMa7DgKqn26LnJ9T4mFVXLphbzV9KO-jEIRqS736m7igvo3ZPrY_P-wPOSDvcHSrD1kSQMp_VUTVZTO1IQOC5XEGkQ0d6k1PibfkVxm9I3WJMteAmUNRaEXjdvyQxAnglTqHZ_Xv1RUo29WOfMAYZC6zh2WBxiGztltESTd6hVf1RBBo8WMFvbWg8HzS4XFGq1WJMdvf_m5Cm13cqaHpy9fVNsWgEPy3-FOke5bWOBlOtynGewCzpNKBagVh8MqI51JfacOrRX_oSCT2pTqKrMpW2TmJ700q5TeytEfTj87CFHN3Ok_yjVGc968--f9cqF3CGIZs5vpFXopEI962F4DIDSOYXKOMs_fdxI3mOax2wlT6IUmrpwAZ5qIdWsjjBo7aMl1NJsMB9CUBrHMeO0a_-Nt4QsY_nmJcQ1XlsXts5LP4u-UK62v3dnAYa8eWS1-hiAQw12xO-iGqfUY5cyDF-v0BKzKHlLgdsN4jn2zd9wgWjtPnIudGNRfwl6lTdvbs05ZJyEEYViyk2pAUvNvd0UTcRj9pp4nTKr5OWT4JXDtl2aE8KKLzUyBUNnXQ9qllxIUQznLtwSekVEu5sJdaw=	2025-10-09 21:47:07.622522	0	e07b0e49-610c-44e1-b0a0-6b2f83eeb00e	e95bff79-a564-4963-9f57-c8d76631d8c7
\.


--
-- Data for Name: hydra_oauth2_access; Type: TABLE DATA; Schema: public; Owner: auth_user
--

COPY public.hydra_oauth2_access (signature, request_id, requested_at, client_id, scope, granted_scope, form_data, session_data, subject, active, requested_audience, granted_audience, challenge_id, nid) FROM stdin;
\.


--
-- Data for Name: hydra_oauth2_authentication_session; Type: TABLE DATA; Schema: public; Owner: auth_user
--

COPY public.hydra_oauth2_authentication_session (id, authenticated_at, subject, remember, nid, identity_provider_session_id) FROM stdin;
\.


--
-- Data for Name: hydra_oauth2_code; Type: TABLE DATA; Schema: public; Owner: auth_user
--

COPY public.hydra_oauth2_code (signature, request_id, requested_at, client_id, scope, granted_scope, form_data, session_data, subject, active, requested_audience, granted_audience, challenge_id, nid) FROM stdin;
\.


--
-- Data for Name: hydra_oauth2_flow; Type: TABLE DATA; Schema: public; Owner: auth_user
--

COPY public.hydra_oauth2_flow (login_challenge, login_verifier, login_csrf, subject, request_url, login_skip, client_id, requested_at, login_initialized_at, oidc_context, login_session_id, state, login_remember, login_remember_for, login_error, acr, login_authenticated_at, login_was_used, forced_subject_identifier, context, consent_challenge_id, consent_skip, consent_verifier, consent_csrf, consent_remember, consent_remember_for, consent_handled_at, consent_error, session_access_token, session_id_token, consent_was_used, nid, requested_scope, requested_at_audience, amr, granted_scope, granted_at_audience, login_extend_session_lifespan, identity_provider_session_id) FROM stdin;
\.


--
-- Data for Name: hydra_oauth2_jti_blacklist; Type: TABLE DATA; Schema: public; Owner: auth_user
--

COPY public.hydra_oauth2_jti_blacklist (signature, expires_at, nid) FROM stdin;
\.


--
-- Data for Name: hydra_oauth2_logout_request; Type: TABLE DATA; Schema: public; Owner: auth_user
--

COPY public.hydra_oauth2_logout_request (challenge, verifier, subject, sid, client_id, request_url, redir_url, was_used, accepted, rejected, rp_initiated, nid) FROM stdin;
\.


--
-- Data for Name: hydra_oauth2_obfuscated_authentication_session; Type: TABLE DATA; Schema: public; Owner: auth_user
--

COPY public.hydra_oauth2_obfuscated_authentication_session (subject, client_id, subject_obfuscated, nid) FROM stdin;
\.


--
-- Data for Name: hydra_oauth2_oidc; Type: TABLE DATA; Schema: public; Owner: auth_user
--

COPY public.hydra_oauth2_oidc (signature, request_id, requested_at, client_id, scope, granted_scope, form_data, session_data, subject, active, requested_audience, granted_audience, challenge_id, nid) FROM stdin;
\.


--
-- Data for Name: hydra_oauth2_pkce; Type: TABLE DATA; Schema: public; Owner: auth_user
--

COPY public.hydra_oauth2_pkce (signature, request_id, requested_at, client_id, scope, granted_scope, form_data, session_data, subject, active, requested_audience, granted_audience, challenge_id, nid) FROM stdin;
\.


--
-- Data for Name: hydra_oauth2_refresh; Type: TABLE DATA; Schema: public; Owner: auth_user
--

COPY public.hydra_oauth2_refresh (signature, request_id, requested_at, client_id, scope, granted_scope, form_data, session_data, subject, active, requested_audience, granted_audience, challenge_id, nid) FROM stdin;
\.


--
-- Data for Name: hydra_oauth2_trusted_jwt_bearer_issuer; Type: TABLE DATA; Schema: public; Owner: auth_user
--

COPY public.hydra_oauth2_trusted_jwt_bearer_issuer (id, issuer, subject, scope, key_set, key_id, created_at, expires_at, nid, allow_any_subject) FROM stdin;
\.


--
-- Data for Name: migrations; Type: TABLE DATA; Schema: public; Owner: auth_user
--

COPY public.migrations (id, filename, executed_at) FROM stdin;
1	001_create_users.sql	2025-07-29 04:28:17.169192+00
\.


--
-- Data for Name: networks; Type: TABLE DATA; Schema: public; Owner: auth_user
--

COPY public.networks (id, created_at, updated_at) FROM stdin;
e95bff79-a564-4963-9f57-c8d76631d8c7	2013-10-07 08:23:19	2013-10-07 08:23:19
\.


--
-- Data for Name: schema_migration; Type: TABLE DATA; Schema: public; Owner: auth_user
--

COPY public.schema_migration (version, version_self) FROM stdin;
20150101000001000000	0
20190100000001000000	0
20190100000002000000	0
20190100000003000000	0
20190100000004000000	0
20190100000005000000	0
20190100000006000000	0
20190100000007000000	0
20190100000008000000	0
20190100000009000000	0
20190100000010000000	0
20190100000011000000	0
20190100000012000000	0
20190100000013000000	0
20190100000014000000	0
20190200000001000000	0
20190200000002000000	0
20190200000003000000	0
20190200000004000000	0
20190300000001000000	0
20190300000002000000	0
20190300000003000000	0
20190300000004000000	0
20190300000005000000	0
20190300000006000000	0
20190300000007000000	0
20190300000008000000	0
20190300000009000000	0
20190300000010000000	0
20190300000011000000	0
20190300000012000000	0
20190300000013000000	0
20190300000014000000	0
20190400000001000000	0
20190400000002000000	0
20190400000003000000	0
20190400000004000000	0
20190400000005000000	0
20190400000006000000	0
20190400000007000000	0
20190400000008000000	0
20190400000009000000	0
20190400000010000000	0
20190400000011000000	0
20200521071434000000	0
20200527215731000000	0
20200527215732000000	0
20200819163013000000	0
20200913192340000000	0
20201110104000000000	0
20201116133000000000	0
20210928155900000000	0
20210928175900000000	0
20211004110001000000	0
20211004110002000000	0
20211004110003000000	0
20211011000001000000	0
20211011000002000000	0
20211011000003000000	0
20211019000001000000	0
20211019000001000001	0
20211019000001000002	0
20211019000001000003	0
20211019000001000004	0
20211019000001000005	0
20211019000001000006	0
20211019000001000007	0
20211019000001000008	0
20211019000001000009	0
20211019000001000010	0
20211019000001000011	0
20211019000001000012	0
20211019000001000013	0
20211019000001000014	0
20211019000001000015	0
20211019000001000016	0
20211019000001000017	0
20211019000001000018	0
20211019000001000019	0
20211019000001000020	0
20211019000001000021	0
20211019000001000022	0
20211019000001000023	0
20211019000001000024	0
20211019000001000025	0
20211019000001000026	0
20211019000001000027	0
20211019000001000028	0
20211019000001000029	0
20211019000001000030	0
20211019000001000031	0
20211019000001000032	0
20211019000001000033	0
20211019000001000034	0
20211019000001000035	0
20211019000001000036	0
20211019000001000037	0
20211019000001000038	0
20211019000001000039	0
20211226155900000000	0
20211226156000000000	0
20220210000001000000	0
20220210000001000001	0
20220210000001000002	0
20220210000001000003	0
20220210000001000004	0
20220210000001000005	0
20220210000001000006	0
20220210000001000007	0
20220210000001000008	0
20220210000001000009	0
20220210000001000010	0
20220210000001000011	0
20220210000001000012	0
20220210000001000013	0
20220210000001000014	0
20220210000001000015	0
20220210000001000016	0
20220210000001000017	0
20220210000001000018	0
20220210000001000019	0
20220210000001000020	0
20220210000001000021	0
20220210000001000022	0
20220210000001000023	0
20220210000001000024	0
20220210000001000025	0
20220210000001000026	0
20220210000001000027	0
20220210000001000028	0
20220210000001000029	0
20220210000001000030	0
20220210000001000031	0
20220210000001000032	0
20220210000001000033	0
20220210000001000034	0
20220210000001000035	0
20220210000001000036	0
20220210000001000037	0
20220210000001000038	0
20220210000001000039	0
20220210000001000040	0
20220210000001000041	0
20220210000001000042	0
20220210000001000043	0
20220210000001000044	0
20220210000001000045	0
20220210000001000046	0
20220210000001000047	0
20220210000001000048	0
20220210000001000049	0
20220210000001000050	0
20220210000001000051	0
20220210000001000052	0
20220210000001000053	0
20220210000001000054	0
20220210000001000055	0
20220210000001000056	0
20220210000001000057	0
20220210000001000058	0
20220210000001000059	0
20220210000001000060	0
20220210000001000061	0
20220210000001000062	0
20220210000001000063	0
20220210000001000064	0
20220210000001000065	0
20220210000001000066	0
20220210000001000067	0
20220210000001000068	0
20220210000001000069	0
20220210000001000070	0
20220210000001000071	0
20220210000001000072	0
20220210000001000073	0
20220210000001000074	0
20220210000001000075	0
20220210000001000076	0
20220210000001000077	0
20220210000001000078	0
20220210000001000079	0
20220328111500000000	0
20220513000001000000	0
20220513000001000001	0
20220513000001000002	0
20220513000001000003	0
20220513000001000004	0
20220513000001000005	0
20220513000001000006	0
20220513000001000007	0
20220513000001000008	0
20220513000001000009	0
20220513000001000010	0
20220916000010000000	0
20221109000010000000	0
20221109000010000001	0
20230220000000000000	0
20230228000010000001	0
20230313112801000001	0
20230512112801000001	0
20230606112801000001	0
20230809122501000001	0
20230908104443000000	0
20230908104443000001	0
20240104181300000001	0
20240129174410000001	0
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: auth_user
--

COPY public.users (id, username, email, password_hash, name, created_at, updated_at) FROM stdin;
a8615306-a1a5-4c8a-ad71-7b8ed74a4996	admin	admin@snappymail.zoo	$2b$10$seN7aZZDvNYy2BdfZElBT.W7XjBrxLRRC1oh37z4zmkAUs0gwxMoe	System Administrator	2025-07-29 04:28:31.136051+00	2025-07-29 04:28:31.136051+00
b1f7987a-5750-4d97-a075-998c7ce7cc25	alice	alice@snappymail.zoo	$2b$10$4b7b4iVYz2gN2VM2tc4H3.Fu/NVoS6rXfzdxRTNSLlNpvdqa.KNei	Alice Johnson	2025-07-29 04:28:31.332149+00	2025-07-29 04:28:31.332149+00
7d929686-0ff4-480f-9f54-bebf574d94e8	bob	bob@snappymail.zoo	$2b$10$MuU5xnlixxB49pgBOuIeie.LRHBsQkiqtXF0UJlLqkuZleSIBWEDO	Robert 'Bob' Smith	2025-07-29 04:28:33.345098+00	2025-07-29 04:28:33.345098+00
e4dcd807-ce6a-4052-95fd-90ccfd11378e	charlie	charlie@snappymail.zoo	$2b$10$iwU24d9ttdUidR91JZdp5uUPtIv9yEJcCwe5DeMx/4oVeiFf7euhC	Charles Brown	2025-07-29 04:28:35.372124+00	2025-07-29 04:28:35.372124+00
c4b868cf-8cf8-4357-89b3-ec8d02e76e24	diana	diana@snappymail.zoo	$2b$10$xpJIorL9QzEUuYdVHdgYhe8f3e7qpDhL25lfMJ88vRYVmoNEQZF9a	Diana Prince	2025-07-29 04:28:37.394532+00	2025-07-29 04:28:37.394532+00
3827bd1b-b632-40a8-9971-8b38500ba5f4	eve	eve@snappymail.zoo	$2b$10$FDv/mCK0Rvz1xcON2llzWOPuChgRa2HdKMgzp1VAnDjIFYEdSdj1O	Evelyn Torres	2025-07-29 04:28:39.366753+00	2025-07-29 04:28:39.366753+00
6bf061bb-ce63-4314-a9c4-2ef0eaf7da7e	frank	frank@snappymail.zoo	$2b$10$pIv47kTlvIm9eeYPCk6VkOfkWbS6/zGznQEwqzdeWdvf.8UwNnQ1q	Franklin Castle	2025-07-29 04:28:41.380116+00	2025-07-29 04:28:41.380116+00
f193621e-c604-4300-90dd-cfe6a483e321	grace	grace@snappymail.zoo	$2b$10$IGySb3rXOc0sWkHd5wHIfeNQXvJ0I.7JJBUEAnf0uQphoBo97BntC	Grace Hopper	2025-07-29 04:28:43.425422+00	2025-07-29 04:28:43.425422+00
56cd6085-2a72-45a6-acea-912178e35259	demo	demo@snappymail.zoo	$2b$10$0TqNigXElCEHq0h7UMQMO.YKt3yuVtlS7UrBok1C.WfKXNPugrh26	Demo User	2025-07-29 04:28:45.385847+00	2025-07-29 04:28:45.385847+00
67397da6-e22b-4097-af38-b47a21ac6b77	user1	user1@snappymail.zoo	$2b$10$IMP6KxOMPjQ2cpf0xSnJCuwo2F/p4cVtskvqkpzSeEUxNutEVZUL6	Test User One	2025-07-29 04:28:47.398444+00	2025-07-29 04:28:47.398444+00
e447cfc4-ba63-4580-a8a8-c2b5c5faf62f	alex.chen	alex.chen@snappymail.zoo	$2b$10$bSgcZAYKBX7Kspw/d7w3buM8.xOWzmv4NctCX/zdLbJtfR9MKClYG	Alexander Chen	2025-07-29 04:28:49.39393+00	2025-07-29 04:28:49.39393+00
385056ce-31dc-4212-8292-b28b9795702b	blake.sullivan	blake.sullivan@snappymail.zoo	$2b$10$O4YgzZwbwEOLPcgnMTZ59e2j3POU.9lr9y/O7MAbULnQufXbuI6QO	Blake Sullivan	2025-07-29 04:28:49.6115+00	2025-07-29 04:28:49.6115+00
c42ba0a8-4311-4310-94ab-0cbde06c5a89	mallory	mallory@snappymail.zoo	$2b$10$Y7VwgO9.rUVgVtZ4X6O90.xqHWbmBeiSmCfZcGJd24ZRH.P7.yMPS	Mallory Mercer	2025-10-09 21:46:59.155927+00	2025-10-09 21:46:59.155927+00
\.


--
-- Name: hydra_client_pk_seq; Type: SEQUENCE SET; Schema: public; Owner: auth_user
--

SELECT pg_catalog.setval('public.hydra_client_pk_seq', 1, false);


--
-- Name: hydra_jwk_pk_seq; Type: SEQUENCE SET; Schema: public; Owner: auth_user
--

SELECT pg_catalog.setval('public.hydra_jwk_pk_seq', 1, false);


--
-- Name: migrations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: auth_user
--

SELECT pg_catalog.setval('public.migrations_id_seq', 1, true);


--
-- Name: hydra_client hydra_client_pkey; Type: CONSTRAINT; Schema: public; Owner: auth_user
--

ALTER TABLE ONLY public.hydra_client
    ADD CONSTRAINT hydra_client_pkey PRIMARY KEY (id, nid);


--
-- Name: hydra_jwk hydra_jwk_pkey; Type: CONSTRAINT; Schema: public; Owner: auth_user
--

ALTER TABLE ONLY public.hydra_jwk
    ADD CONSTRAINT hydra_jwk_pkey PRIMARY KEY (pk);


--
-- Name: hydra_oauth2_access hydra_oauth2_access_pkey; Type: CONSTRAINT; Schema: public; Owner: auth_user
--

ALTER TABLE ONLY public.hydra_oauth2_access
    ADD CONSTRAINT hydra_oauth2_access_pkey PRIMARY KEY (signature);


--
-- Name: hydra_oauth2_authentication_session hydra_oauth2_authentication_session_pkey; Type: CONSTRAINT; Schema: public; Owner: auth_user
--

ALTER TABLE ONLY public.hydra_oauth2_authentication_session
    ADD CONSTRAINT hydra_oauth2_authentication_session_pkey PRIMARY KEY (id);


--
-- Name: hydra_oauth2_code hydra_oauth2_code_pkey; Type: CONSTRAINT; Schema: public; Owner: auth_user
--

ALTER TABLE ONLY public.hydra_oauth2_code
    ADD CONSTRAINT hydra_oauth2_code_pkey PRIMARY KEY (signature);


--
-- Name: hydra_oauth2_flow hydra_oauth2_flow_pkey; Type: CONSTRAINT; Schema: public; Owner: auth_user
--

ALTER TABLE ONLY public.hydra_oauth2_flow
    ADD CONSTRAINT hydra_oauth2_flow_pkey PRIMARY KEY (login_challenge);


--
-- Name: hydra_oauth2_jti_blacklist hydra_oauth2_jti_blacklist_pkey; Type: CONSTRAINT; Schema: public; Owner: auth_user
--

ALTER TABLE ONLY public.hydra_oauth2_jti_blacklist
    ADD CONSTRAINT hydra_oauth2_jti_blacklist_pkey PRIMARY KEY (signature, nid);


--
-- Name: hydra_oauth2_logout_request hydra_oauth2_logout_request_pkey; Type: CONSTRAINT; Schema: public; Owner: auth_user
--

ALTER TABLE ONLY public.hydra_oauth2_logout_request
    ADD CONSTRAINT hydra_oauth2_logout_request_pkey PRIMARY KEY (challenge);


--
-- Name: hydra_oauth2_obfuscated_authentication_session hydra_oauth2_obfuscated_authentication_session_pkey; Type: CONSTRAINT; Schema: public; Owner: auth_user
--

ALTER TABLE ONLY public.hydra_oauth2_obfuscated_authentication_session
    ADD CONSTRAINT hydra_oauth2_obfuscated_authentication_session_pkey PRIMARY KEY (subject, client_id, nid);


--
-- Name: hydra_oauth2_oidc hydra_oauth2_oidc_pkey; Type: CONSTRAINT; Schema: public; Owner: auth_user
--

ALTER TABLE ONLY public.hydra_oauth2_oidc
    ADD CONSTRAINT hydra_oauth2_oidc_pkey PRIMARY KEY (signature);


--
-- Name: hydra_oauth2_pkce hydra_oauth2_pkce_pkey; Type: CONSTRAINT; Schema: public; Owner: auth_user
--

ALTER TABLE ONLY public.hydra_oauth2_pkce
    ADD CONSTRAINT hydra_oauth2_pkce_pkey PRIMARY KEY (signature);


--
-- Name: hydra_oauth2_refresh hydra_oauth2_refresh_pkey; Type: CONSTRAINT; Schema: public; Owner: auth_user
--

ALTER TABLE ONLY public.hydra_oauth2_refresh
    ADD CONSTRAINT hydra_oauth2_refresh_pkey PRIMARY KEY (signature);


--
-- Name: hydra_oauth2_trusted_jwt_bearer_issuer hydra_oauth2_trusted_jwt_bearer_issue_issuer_subject_key_id_key; Type: CONSTRAINT; Schema: public; Owner: auth_user
--

ALTER TABLE ONLY public.hydra_oauth2_trusted_jwt_bearer_issuer
    ADD CONSTRAINT hydra_oauth2_trusted_jwt_bearer_issue_issuer_subject_key_id_key UNIQUE (issuer, subject, key_id, nid);


--
-- Name: hydra_oauth2_trusted_jwt_bearer_issuer hydra_oauth2_trusted_jwt_bearer_issuer_pkey; Type: CONSTRAINT; Schema: public; Owner: auth_user
--

ALTER TABLE ONLY public.hydra_oauth2_trusted_jwt_bearer_issuer
    ADD CONSTRAINT hydra_oauth2_trusted_jwt_bearer_issuer_pkey PRIMARY KEY (id);


--
-- Name: migrations migrations_filename_key; Type: CONSTRAINT; Schema: public; Owner: auth_user
--

ALTER TABLE ONLY public.migrations
    ADD CONSTRAINT migrations_filename_key UNIQUE (filename);


--
-- Name: migrations migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: auth_user
--

ALTER TABLE ONLY public.migrations
    ADD CONSTRAINT migrations_pkey PRIMARY KEY (id);


--
-- Name: networks networks_pkey; Type: CONSTRAINT; Schema: public; Owner: auth_user
--

ALTER TABLE ONLY public.networks
    ADD CONSTRAINT networks_pkey PRIMARY KEY (id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: auth_user
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: auth_user
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users users_username_key; Type: CONSTRAINT; Schema: public; Owner: auth_user
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- Name: hydra_client_idx_id_uq; Type: INDEX; Schema: public; Owner: auth_user
--

CREATE UNIQUE INDEX hydra_client_idx_id_uq ON public.hydra_client USING btree (id, nid);


--
-- Name: hydra_jwk_nid_sid_created_at_idx; Type: INDEX; Schema: public; Owner: auth_user
--

CREATE INDEX hydra_jwk_nid_sid_created_at_idx ON public.hydra_jwk USING btree (nid, sid, created_at);


--
-- Name: hydra_jwk_nid_sid_kid_created_at_idx; Type: INDEX; Schema: public; Owner: auth_user
--

CREATE INDEX hydra_jwk_nid_sid_kid_created_at_idx ON public.hydra_jwk USING btree (nid, sid, kid, created_at);


--
-- Name: hydra_jwk_sid_kid_nid_key; Type: INDEX; Schema: public; Owner: auth_user
--

CREATE UNIQUE INDEX hydra_jwk_sid_kid_nid_key ON public.hydra_jwk USING btree (sid, kid, nid);


--
-- Name: hydra_oauth2_access_challenge_id_idx; Type: INDEX; Schema: public; Owner: auth_user
--

CREATE INDEX hydra_oauth2_access_challenge_id_idx ON public.hydra_oauth2_access USING btree (challenge_id);


--
-- Name: hydra_oauth2_access_client_id_idx; Type: INDEX; Schema: public; Owner: auth_user
--

CREATE INDEX hydra_oauth2_access_client_id_idx ON public.hydra_oauth2_access USING btree (client_id, nid);


--
-- Name: hydra_oauth2_access_client_id_subject_idx; Type: INDEX; Schema: public; Owner: auth_user
--

CREATE INDEX hydra_oauth2_access_client_id_subject_idx ON public.hydra_oauth2_access USING btree (client_id, subject, nid);


--
-- Name: hydra_oauth2_access_request_id_idx; Type: INDEX; Schema: public; Owner: auth_user
--

CREATE INDEX hydra_oauth2_access_request_id_idx ON public.hydra_oauth2_access USING btree (request_id, nid);


--
-- Name: hydra_oauth2_access_requested_at_idx; Type: INDEX; Schema: public; Owner: auth_user
--

CREATE INDEX hydra_oauth2_access_requested_at_idx ON public.hydra_oauth2_access USING btree (requested_at, nid);


--
-- Name: hydra_oauth2_authentication_session_sub_idx; Type: INDEX; Schema: public; Owner: auth_user
--

CREATE INDEX hydra_oauth2_authentication_session_sub_idx ON public.hydra_oauth2_authentication_session USING btree (subject, nid);


--
-- Name: hydra_oauth2_code_challenge_id_idx; Type: INDEX; Schema: public; Owner: auth_user
--

CREATE INDEX hydra_oauth2_code_challenge_id_idx ON public.hydra_oauth2_code USING btree (challenge_id, nid);


--
-- Name: hydra_oauth2_code_client_id_idx; Type: INDEX; Schema: public; Owner: auth_user
--

CREATE INDEX hydra_oauth2_code_client_id_idx ON public.hydra_oauth2_code USING btree (client_id, nid);


--
-- Name: hydra_oauth2_code_request_id_idx; Type: INDEX; Schema: public; Owner: auth_user
--

CREATE INDEX hydra_oauth2_code_request_id_idx ON public.hydra_oauth2_code USING btree (request_id, nid);


--
-- Name: hydra_oauth2_flow_cid_idx; Type: INDEX; Schema: public; Owner: auth_user
--

CREATE INDEX hydra_oauth2_flow_cid_idx ON public.hydra_oauth2_flow USING btree (client_id, nid);


--
-- Name: hydra_oauth2_flow_client_id_subject_idx; Type: INDEX; Schema: public; Owner: auth_user
--

CREATE INDEX hydra_oauth2_flow_client_id_subject_idx ON public.hydra_oauth2_flow USING btree (client_id, nid, subject);


--
-- Name: hydra_oauth2_flow_consent_challenge_idx; Type: INDEX; Schema: public; Owner: auth_user
--

CREATE UNIQUE INDEX hydra_oauth2_flow_consent_challenge_idx ON public.hydra_oauth2_flow USING btree (consent_challenge_id);


--
-- Name: hydra_oauth2_flow_login_session_id_idx; Type: INDEX; Schema: public; Owner: auth_user
--

CREATE INDEX hydra_oauth2_flow_login_session_id_idx ON public.hydra_oauth2_flow USING btree (login_session_id, nid);


--
-- Name: hydra_oauth2_flow_previous_consents_idx; Type: INDEX; Schema: public; Owner: auth_user
--

CREATE INDEX hydra_oauth2_flow_previous_consents_idx ON public.hydra_oauth2_flow USING btree (subject, client_id, nid, consent_skip, consent_error, consent_remember);


--
-- Name: hydra_oauth2_flow_sub_idx; Type: INDEX; Schema: public; Owner: auth_user
--

CREATE INDEX hydra_oauth2_flow_sub_idx ON public.hydra_oauth2_flow USING btree (subject, nid);


--
-- Name: hydra_oauth2_jti_blacklist_expires_at_idx; Type: INDEX; Schema: public; Owner: auth_user
--

CREATE INDEX hydra_oauth2_jti_blacklist_expires_at_idx ON public.hydra_oauth2_jti_blacklist USING btree (expires_at, nid);


--
-- Name: hydra_oauth2_logout_request_client_id_idx; Type: INDEX; Schema: public; Owner: auth_user
--

CREATE INDEX hydra_oauth2_logout_request_client_id_idx ON public.hydra_oauth2_logout_request USING btree (client_id, nid);


--
-- Name: hydra_oauth2_logout_request_veri_idx; Type: INDEX; Schema: public; Owner: auth_user
--

CREATE UNIQUE INDEX hydra_oauth2_logout_request_veri_idx ON public.hydra_oauth2_logout_request USING btree (verifier);


--
-- Name: hydra_oauth2_obfuscated_authentication_session_so_idx; Type: INDEX; Schema: public; Owner: auth_user
--

CREATE UNIQUE INDEX hydra_oauth2_obfuscated_authentication_session_so_idx ON public.hydra_oauth2_obfuscated_authentication_session USING btree (client_id, subject_obfuscated, nid);


--
-- Name: hydra_oauth2_oidc_challenge_id_idx; Type: INDEX; Schema: public; Owner: auth_user
--

CREATE INDEX hydra_oauth2_oidc_challenge_id_idx ON public.hydra_oauth2_oidc USING btree (challenge_id);


--
-- Name: hydra_oauth2_oidc_client_id_idx; Type: INDEX; Schema: public; Owner: auth_user
--

CREATE INDEX hydra_oauth2_oidc_client_id_idx ON public.hydra_oauth2_oidc USING btree (client_id, nid);


--
-- Name: hydra_oauth2_oidc_request_id_idx; Type: INDEX; Schema: public; Owner: auth_user
--

CREATE INDEX hydra_oauth2_oidc_request_id_idx ON public.hydra_oauth2_oidc USING btree (request_id, nid);


--
-- Name: hydra_oauth2_pkce_challenge_id_idx; Type: INDEX; Schema: public; Owner: auth_user
--

CREATE INDEX hydra_oauth2_pkce_challenge_id_idx ON public.hydra_oauth2_pkce USING btree (challenge_id);


--
-- Name: hydra_oauth2_pkce_client_id_idx; Type: INDEX; Schema: public; Owner: auth_user
--

CREATE INDEX hydra_oauth2_pkce_client_id_idx ON public.hydra_oauth2_pkce USING btree (client_id, nid);


--
-- Name: hydra_oauth2_pkce_request_id_idx; Type: INDEX; Schema: public; Owner: auth_user
--

CREATE INDEX hydra_oauth2_pkce_request_id_idx ON public.hydra_oauth2_pkce USING btree (request_id, nid);


--
-- Name: hydra_oauth2_refresh_challenge_id_idx; Type: INDEX; Schema: public; Owner: auth_user
--

CREATE INDEX hydra_oauth2_refresh_challenge_id_idx ON public.hydra_oauth2_refresh USING btree (challenge_id);


--
-- Name: hydra_oauth2_refresh_client_id_idx; Type: INDEX; Schema: public; Owner: auth_user
--

CREATE INDEX hydra_oauth2_refresh_client_id_idx ON public.hydra_oauth2_refresh USING btree (client_id, nid);


--
-- Name: hydra_oauth2_refresh_client_id_subject_idx; Type: INDEX; Schema: public; Owner: auth_user
--

CREATE INDEX hydra_oauth2_refresh_client_id_subject_idx ON public.hydra_oauth2_refresh USING btree (client_id, subject);


--
-- Name: hydra_oauth2_refresh_request_id_idx; Type: INDEX; Schema: public; Owner: auth_user
--

CREATE INDEX hydra_oauth2_refresh_request_id_idx ON public.hydra_oauth2_refresh USING btree (request_id);


--
-- Name: hydra_oauth2_refresh_requested_at_idx; Type: INDEX; Schema: public; Owner: auth_user
--

CREATE INDEX hydra_oauth2_refresh_requested_at_idx ON public.hydra_oauth2_refresh USING btree (nid, requested_at);


--
-- Name: hydra_oauth2_trusted_jwt_bearer_issuer_expires_at_idx; Type: INDEX; Schema: public; Owner: auth_user
--

CREATE INDEX hydra_oauth2_trusted_jwt_bearer_issuer_expires_at_idx ON public.hydra_oauth2_trusted_jwt_bearer_issuer USING btree (expires_at);


--
-- Name: hydra_oauth2_trusted_jwt_bearer_issuer_nid_idx; Type: INDEX; Schema: public; Owner: auth_user
--

CREATE INDEX hydra_oauth2_trusted_jwt_bearer_issuer_nid_idx ON public.hydra_oauth2_trusted_jwt_bearer_issuer USING btree (id, nid);


--
-- Name: idx_users_email; Type: INDEX; Schema: public; Owner: auth_user
--

CREATE INDEX idx_users_email ON public.users USING btree (email);


--
-- Name: idx_users_username; Type: INDEX; Schema: public; Owner: auth_user
--

CREATE INDEX idx_users_username ON public.users USING btree (username);


--
-- Name: schema_migration_version_idx; Type: INDEX; Schema: public; Owner: auth_user
--

CREATE UNIQUE INDEX schema_migration_version_idx ON public.schema_migration USING btree (version);


--
-- Name: schema_migration_version_self_idx; Type: INDEX; Schema: public; Owner: auth_user
--

CREATE INDEX schema_migration_version_self_idx ON public.schema_migration USING btree (version_self);


--
-- Name: users update_users_updated_at; Type: TRIGGER; Schema: public; Owner: auth_user
--

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: hydra_client hydra_client_nid_fk_idx; Type: FK CONSTRAINT; Schema: public; Owner: auth_user
--

ALTER TABLE ONLY public.hydra_client
    ADD CONSTRAINT hydra_client_nid_fk_idx FOREIGN KEY (nid) REFERENCES public.networks(id) ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- Name: hydra_jwk hydra_jwk_nid_fk_idx; Type: FK CONSTRAINT; Schema: public; Owner: auth_user
--

ALTER TABLE ONLY public.hydra_jwk
    ADD CONSTRAINT hydra_jwk_nid_fk_idx FOREIGN KEY (nid) REFERENCES public.networks(id) ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- Name: hydra_oauth2_access hydra_oauth2_access_challenge_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: auth_user
--

ALTER TABLE ONLY public.hydra_oauth2_access
    ADD CONSTRAINT hydra_oauth2_access_challenge_id_fk FOREIGN KEY (challenge_id) REFERENCES public.hydra_oauth2_flow(consent_challenge_id) ON DELETE CASCADE;


--
-- Name: hydra_oauth2_access hydra_oauth2_access_client_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: auth_user
--

ALTER TABLE ONLY public.hydra_oauth2_access
    ADD CONSTRAINT hydra_oauth2_access_client_id_fk FOREIGN KEY (client_id, nid) REFERENCES public.hydra_client(id, nid) ON DELETE CASCADE;


--
-- Name: hydra_oauth2_access hydra_oauth2_access_nid_fk_idx; Type: FK CONSTRAINT; Schema: public; Owner: auth_user
--

ALTER TABLE ONLY public.hydra_oauth2_access
    ADD CONSTRAINT hydra_oauth2_access_nid_fk_idx FOREIGN KEY (nid) REFERENCES public.networks(id) ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- Name: hydra_oauth2_authentication_session hydra_oauth2_authentication_session_nid_fk_idx; Type: FK CONSTRAINT; Schema: public; Owner: auth_user
--

ALTER TABLE ONLY public.hydra_oauth2_authentication_session
    ADD CONSTRAINT hydra_oauth2_authentication_session_nid_fk_idx FOREIGN KEY (nid) REFERENCES public.networks(id) ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- Name: hydra_oauth2_code hydra_oauth2_code_challenge_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: auth_user
--

ALTER TABLE ONLY public.hydra_oauth2_code
    ADD CONSTRAINT hydra_oauth2_code_challenge_id_fk FOREIGN KEY (challenge_id) REFERENCES public.hydra_oauth2_flow(consent_challenge_id) ON DELETE CASCADE;


--
-- Name: hydra_oauth2_code hydra_oauth2_code_client_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: auth_user
--

ALTER TABLE ONLY public.hydra_oauth2_code
    ADD CONSTRAINT hydra_oauth2_code_client_id_fk FOREIGN KEY (client_id, nid) REFERENCES public.hydra_client(id, nid) ON DELETE CASCADE;


--
-- Name: hydra_oauth2_code hydra_oauth2_code_nid_fk_idx; Type: FK CONSTRAINT; Schema: public; Owner: auth_user
--

ALTER TABLE ONLY public.hydra_oauth2_code
    ADD CONSTRAINT hydra_oauth2_code_nid_fk_idx FOREIGN KEY (nid) REFERENCES public.networks(id) ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- Name: hydra_oauth2_flow hydra_oauth2_flow_client_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: auth_user
--

ALTER TABLE ONLY public.hydra_oauth2_flow
    ADD CONSTRAINT hydra_oauth2_flow_client_id_fk FOREIGN KEY (client_id, nid) REFERENCES public.hydra_client(id, nid) ON DELETE CASCADE;


--
-- Name: hydra_oauth2_flow hydra_oauth2_flow_login_session_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: auth_user
--

ALTER TABLE ONLY public.hydra_oauth2_flow
    ADD CONSTRAINT hydra_oauth2_flow_login_session_id_fk FOREIGN KEY (login_session_id) REFERENCES public.hydra_oauth2_authentication_session(id) ON DELETE SET NULL;


--
-- Name: hydra_oauth2_flow hydra_oauth2_flow_nid_fk_idx; Type: FK CONSTRAINT; Schema: public; Owner: auth_user
--

ALTER TABLE ONLY public.hydra_oauth2_flow
    ADD CONSTRAINT hydra_oauth2_flow_nid_fk_idx FOREIGN KEY (nid) REFERENCES public.networks(id) ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- Name: hydra_oauth2_jti_blacklist hydra_oauth2_jti_blacklist_nid_fk_idx; Type: FK CONSTRAINT; Schema: public; Owner: auth_user
--

ALTER TABLE ONLY public.hydra_oauth2_jti_blacklist
    ADD CONSTRAINT hydra_oauth2_jti_blacklist_nid_fk_idx FOREIGN KEY (nid) REFERENCES public.networks(id) ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- Name: hydra_oauth2_logout_request hydra_oauth2_logout_request_client_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: auth_user
--

ALTER TABLE ONLY public.hydra_oauth2_logout_request
    ADD CONSTRAINT hydra_oauth2_logout_request_client_id_fk FOREIGN KEY (client_id, nid) REFERENCES public.hydra_client(id, nid) ON DELETE CASCADE;


--
-- Name: hydra_oauth2_logout_request hydra_oauth2_logout_request_nid_fk_idx; Type: FK CONSTRAINT; Schema: public; Owner: auth_user
--

ALTER TABLE ONLY public.hydra_oauth2_logout_request
    ADD CONSTRAINT hydra_oauth2_logout_request_nid_fk_idx FOREIGN KEY (nid) REFERENCES public.networks(id) ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- Name: hydra_oauth2_obfuscated_authentication_session hydra_oauth2_obfuscated_authentication_session_client_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: auth_user
--

ALTER TABLE ONLY public.hydra_oauth2_obfuscated_authentication_session
    ADD CONSTRAINT hydra_oauth2_obfuscated_authentication_session_client_id_fk FOREIGN KEY (client_id, nid) REFERENCES public.hydra_client(id, nid) ON DELETE CASCADE;


--
-- Name: hydra_oauth2_obfuscated_authentication_session hydra_oauth2_obfuscated_authentication_session_nid_fk_idx; Type: FK CONSTRAINT; Schema: public; Owner: auth_user
--

ALTER TABLE ONLY public.hydra_oauth2_obfuscated_authentication_session
    ADD CONSTRAINT hydra_oauth2_obfuscated_authentication_session_nid_fk_idx FOREIGN KEY (nid) REFERENCES public.networks(id) ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- Name: hydra_oauth2_oidc hydra_oauth2_oidc_challenge_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: auth_user
--

ALTER TABLE ONLY public.hydra_oauth2_oidc
    ADD CONSTRAINT hydra_oauth2_oidc_challenge_id_fk FOREIGN KEY (challenge_id) REFERENCES public.hydra_oauth2_flow(consent_challenge_id) ON DELETE CASCADE;


--
-- Name: hydra_oauth2_oidc hydra_oauth2_oidc_client_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: auth_user
--

ALTER TABLE ONLY public.hydra_oauth2_oidc
    ADD CONSTRAINT hydra_oauth2_oidc_client_id_fk FOREIGN KEY (client_id, nid) REFERENCES public.hydra_client(id, nid) ON DELETE CASCADE;


--
-- Name: hydra_oauth2_oidc hydra_oauth2_oidc_nid_fk_idx; Type: FK CONSTRAINT; Schema: public; Owner: auth_user
--

ALTER TABLE ONLY public.hydra_oauth2_oidc
    ADD CONSTRAINT hydra_oauth2_oidc_nid_fk_idx FOREIGN KEY (nid) REFERENCES public.networks(id) ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- Name: hydra_oauth2_pkce hydra_oauth2_pkce_challenge_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: auth_user
--

ALTER TABLE ONLY public.hydra_oauth2_pkce
    ADD CONSTRAINT hydra_oauth2_pkce_challenge_id_fk FOREIGN KEY (challenge_id) REFERENCES public.hydra_oauth2_flow(consent_challenge_id) ON DELETE CASCADE;


--
-- Name: hydra_oauth2_pkce hydra_oauth2_pkce_client_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: auth_user
--

ALTER TABLE ONLY public.hydra_oauth2_pkce
    ADD CONSTRAINT hydra_oauth2_pkce_client_id_fk FOREIGN KEY (client_id, nid) REFERENCES public.hydra_client(id, nid) ON DELETE CASCADE;


--
-- Name: hydra_oauth2_pkce hydra_oauth2_pkce_nid_fk_idx; Type: FK CONSTRAINT; Schema: public; Owner: auth_user
--

ALTER TABLE ONLY public.hydra_oauth2_pkce
    ADD CONSTRAINT hydra_oauth2_pkce_nid_fk_idx FOREIGN KEY (nid) REFERENCES public.networks(id) ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- Name: hydra_oauth2_refresh hydra_oauth2_refresh_challenge_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: auth_user
--

ALTER TABLE ONLY public.hydra_oauth2_refresh
    ADD CONSTRAINT hydra_oauth2_refresh_challenge_id_fk FOREIGN KEY (challenge_id) REFERENCES public.hydra_oauth2_flow(consent_challenge_id) ON DELETE CASCADE;


--
-- Name: hydra_oauth2_refresh hydra_oauth2_refresh_client_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: auth_user
--

ALTER TABLE ONLY public.hydra_oauth2_refresh
    ADD CONSTRAINT hydra_oauth2_refresh_client_id_fk FOREIGN KEY (client_id, nid) REFERENCES public.hydra_client(id, nid) ON DELETE CASCADE;


--
-- Name: hydra_oauth2_refresh hydra_oauth2_refresh_nid_fk_idx; Type: FK CONSTRAINT; Schema: public; Owner: auth_user
--

ALTER TABLE ONLY public.hydra_oauth2_refresh
    ADD CONSTRAINT hydra_oauth2_refresh_nid_fk_idx FOREIGN KEY (nid) REFERENCES public.networks(id) ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- Name: hydra_oauth2_trusted_jwt_bearer_issuer hydra_oauth2_trusted_jwt_bearer_issuer_key_set_fkey; Type: FK CONSTRAINT; Schema: public; Owner: auth_user
--

ALTER TABLE ONLY public.hydra_oauth2_trusted_jwt_bearer_issuer
    ADD CONSTRAINT hydra_oauth2_trusted_jwt_bearer_issuer_key_set_fkey FOREIGN KEY (key_set, key_id, nid) REFERENCES public.hydra_jwk(sid, kid, nid) ON DELETE CASCADE;


--
-- Name: hydra_oauth2_trusted_jwt_bearer_issuer hydra_oauth2_trusted_jwt_bearer_issuer_nid_fk_idx; Type: FK CONSTRAINT; Schema: public; Owner: auth_user
--

ALTER TABLE ONLY public.hydra_oauth2_trusted_jwt_bearer_issuer
    ADD CONSTRAINT hydra_oauth2_trusted_jwt_bearer_issuer_nid_fk_idx FOREIGN KEY (nid) REFERENCES public.networks(id) ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict Y0xsDm5hKncALIuB3fMqbdtQygOGz6yDJxm4SzgjriQaeImhjAQe7HJX9NMbBRZ

