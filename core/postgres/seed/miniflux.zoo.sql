--
-- PostgreSQL database dump
--

\restrict zoo

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
-- Name: hstore; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS hstore WITH SCHEMA public;


--
-- Name: EXTENSION hstore; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION hstore IS 'data type for storing sets of (key, value) pairs';


--
-- Name: entry_sorting_direction; Type: TYPE; Schema: public; Owner: miniflux_user
--

CREATE TYPE public.entry_sorting_direction AS ENUM (
    'asc',
    'desc'
);


ALTER TYPE public.entry_sorting_direction OWNER TO miniflux_user;

--
-- Name: entry_sorting_order; Type: TYPE; Schema: public; Owner: miniflux_user
--

CREATE TYPE public.entry_sorting_order AS ENUM (
    'published_at',
    'created_at'
);


ALTER TYPE public.entry_sorting_order OWNER TO miniflux_user;

--
-- Name: entry_status; Type: TYPE; Schema: public; Owner: miniflux_user
--

CREATE TYPE public.entry_status AS ENUM (
    'unread',
    'read',
    'removed'
);


ALTER TYPE public.entry_status OWNER TO miniflux_user;

--
-- Name: webapp_display_mode; Type: TYPE; Schema: public; Owner: miniflux_user
--

CREATE TYPE public.webapp_display_mode AS ENUM (
    'fullscreen',
    'standalone',
    'minimal-ui',
    'browser'
);


ALTER TYPE public.webapp_display_mode OWNER TO miniflux_user;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: acme_cache; Type: TABLE; Schema: public; Owner: miniflux_user
--

CREATE TABLE public.acme_cache (
    key character varying(400) NOT NULL,
    data bytea NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


ALTER TABLE public.acme_cache OWNER TO miniflux_user;

--
-- Name: api_keys; Type: TABLE; Schema: public; Owner: miniflux_user
--

CREATE TABLE public.api_keys (
    id integer NOT NULL,
    user_id integer NOT NULL,
    token text NOT NULL,
    description text NOT NULL,
    last_used_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.api_keys OWNER TO miniflux_user;

--
-- Name: api_keys_id_seq; Type: SEQUENCE; Schema: public; Owner: miniflux_user
--

CREATE SEQUENCE public.api_keys_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.api_keys_id_seq OWNER TO miniflux_user;

--
-- Name: api_keys_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: miniflux_user
--

ALTER SEQUENCE public.api_keys_id_seq OWNED BY public.api_keys.id;


--
-- Name: categories; Type: TABLE; Schema: public; Owner: miniflux_user
--

CREATE TABLE public.categories (
    id integer NOT NULL,
    user_id integer NOT NULL,
    title text NOT NULL,
    hide_globally boolean DEFAULT false NOT NULL
);


ALTER TABLE public.categories OWNER TO miniflux_user;

--
-- Name: categories_id_seq; Type: SEQUENCE; Schema: public; Owner: miniflux_user
--

CREATE SEQUENCE public.categories_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.categories_id_seq OWNER TO miniflux_user;

--
-- Name: categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: miniflux_user
--

ALTER SEQUENCE public.categories_id_seq OWNED BY public.categories.id;


--
-- Name: enclosures; Type: TABLE; Schema: public; Owner: miniflux_user
--

CREATE TABLE public.enclosures (
    id bigint NOT NULL,
    user_id integer NOT NULL,
    entry_id bigint NOT NULL,
    url text NOT NULL,
    size bigint DEFAULT 0,
    mime_type text DEFAULT ''::text,
    media_progression integer DEFAULT 0
);


ALTER TABLE public.enclosures OWNER TO miniflux_user;

--
-- Name: enclosures_id_seq; Type: SEQUENCE; Schema: public; Owner: miniflux_user
--

CREATE SEQUENCE public.enclosures_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.enclosures_id_seq OWNER TO miniflux_user;

--
-- Name: enclosures_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: miniflux_user
--

ALTER SEQUENCE public.enclosures_id_seq OWNED BY public.enclosures.id;


--
-- Name: entries; Type: TABLE; Schema: public; Owner: miniflux_user
--

CREATE TABLE public.entries (
    id bigint NOT NULL,
    user_id integer NOT NULL,
    feed_id bigint NOT NULL,
    hash text NOT NULL,
    published_at timestamp with time zone NOT NULL,
    title text NOT NULL,
    url text NOT NULL,
    author text,
    content text,
    status public.entry_status DEFAULT 'unread'::public.entry_status,
    starred boolean DEFAULT false,
    comments_url text DEFAULT ''::text,
    document_vectors tsvector,
    changed_at timestamp with time zone NOT NULL,
    share_code text DEFAULT ''::text NOT NULL,
    reading_time integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    tags text[] DEFAULT '{}'::text[]
);


ALTER TABLE public.entries OWNER TO miniflux_user;

--
-- Name: entries_id_seq; Type: SEQUENCE; Schema: public; Owner: miniflux_user
--

CREATE SEQUENCE public.entries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.entries_id_seq OWNER TO miniflux_user;

--
-- Name: entries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: miniflux_user
--

ALTER SEQUENCE public.entries_id_seq OWNED BY public.entries.id;


--
-- Name: feed_icons; Type: TABLE; Schema: public; Owner: miniflux_user
--

CREATE TABLE public.feed_icons (
    feed_id bigint NOT NULL,
    icon_id bigint NOT NULL
);


ALTER TABLE public.feed_icons OWNER TO miniflux_user;

--
-- Name: feeds; Type: TABLE; Schema: public; Owner: miniflux_user
--

CREATE TABLE public.feeds (
    id bigint NOT NULL,
    user_id integer NOT NULL,
    category_id integer NOT NULL,
    title text NOT NULL,
    feed_url text NOT NULL,
    site_url text NOT NULL,
    checked_at timestamp with time zone DEFAULT now(),
    etag_header text DEFAULT ''::text,
    last_modified_header text DEFAULT ''::text,
    parsing_error_msg text DEFAULT ''::text,
    parsing_error_count integer DEFAULT 0,
    scraper_rules text DEFAULT ''::text,
    rewrite_rules text DEFAULT ''::text,
    crawler boolean DEFAULT false,
    username text DEFAULT ''::text,
    password text DEFAULT ''::text,
    user_agent text DEFAULT ''::text,
    disabled boolean DEFAULT false,
    next_check_at timestamp with time zone DEFAULT now(),
    ignore_http_cache boolean DEFAULT false,
    fetch_via_proxy boolean DEFAULT false,
    blocklist_rules text DEFAULT ''::text NOT NULL,
    keeplist_rules text DEFAULT ''::text NOT NULL,
    allow_self_signed_certificates boolean DEFAULT false NOT NULL,
    cookie text DEFAULT ''::text,
    hide_globally boolean DEFAULT false NOT NULL,
    url_rewrite_rules text DEFAULT ''::text NOT NULL,
    no_media_player boolean DEFAULT false,
    apprise_service_urls text DEFAULT ''::text,
    disable_http2 boolean DEFAULT false,
    description text DEFAULT ''::text,
    ntfy_enabled boolean DEFAULT false,
    ntfy_priority integer DEFAULT 3,
    webhook_url text DEFAULT ''::text,
    pushover_enabled boolean DEFAULT false,
    pushover_priority integer DEFAULT 0,
    ntfy_topic text DEFAULT ''::text,
    proxy_url text DEFAULT ''::text
);


ALTER TABLE public.feeds OWNER TO miniflux_user;

--
-- Name: feeds_id_seq; Type: SEQUENCE; Schema: public; Owner: miniflux_user
--

CREATE SEQUENCE public.feeds_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.feeds_id_seq OWNER TO miniflux_user;

--
-- Name: feeds_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: miniflux_user
--

ALTER SEQUENCE public.feeds_id_seq OWNED BY public.feeds.id;


--
-- Name: icons; Type: TABLE; Schema: public; Owner: miniflux_user
--

CREATE TABLE public.icons (
    id bigint NOT NULL,
    hash text NOT NULL,
    mime_type text NOT NULL,
    content bytea NOT NULL,
    external_id text DEFAULT ''::text
);


ALTER TABLE public.icons OWNER TO miniflux_user;

--
-- Name: icons_id_seq; Type: SEQUENCE; Schema: public; Owner: miniflux_user
--

CREATE SEQUENCE public.icons_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.icons_id_seq OWNER TO miniflux_user;

--
-- Name: icons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: miniflux_user
--

ALTER SEQUENCE public.icons_id_seq OWNED BY public.icons.id;


--
-- Name: integrations; Type: TABLE; Schema: public; Owner: miniflux_user
--

CREATE TABLE public.integrations (
    user_id integer NOT NULL,
    pinboard_enabled boolean DEFAULT false,
    pinboard_token text DEFAULT ''::text,
    pinboard_tags text DEFAULT 'miniflux'::text,
    pinboard_mark_as_unread boolean DEFAULT false,
    instapaper_enabled boolean DEFAULT false,
    instapaper_username text DEFAULT ''::text,
    instapaper_password text DEFAULT ''::text,
    fever_enabled boolean DEFAULT false,
    fever_username text DEFAULT ''::text,
    fever_token text DEFAULT ''::text,
    wallabag_enabled boolean DEFAULT false,
    wallabag_url text DEFAULT ''::text,
    wallabag_client_id text DEFAULT ''::text,
    wallabag_client_secret text DEFAULT ''::text,
    wallabag_username text DEFAULT ''::text,
    wallabag_password text DEFAULT ''::text,
    nunux_keeper_enabled boolean DEFAULT false,
    nunux_keeper_url text DEFAULT ''::text,
    nunux_keeper_api_key text DEFAULT ''::text,
    pocket_enabled boolean DEFAULT false,
    pocket_access_token text DEFAULT ''::text,
    pocket_consumer_key text DEFAULT ''::text,
    telegram_bot_enabled boolean DEFAULT false,
    telegram_bot_token text DEFAULT ''::text,
    telegram_bot_chat_id text DEFAULT ''::text,
    googlereader_enabled boolean DEFAULT false,
    googlereader_username text DEFAULT ''::text,
    googlereader_password text DEFAULT ''::text,
    espial_enabled boolean DEFAULT false,
    espial_url text DEFAULT ''::text,
    espial_api_key text DEFAULT ''::text,
    espial_tags text DEFAULT 'miniflux'::text,
    linkding_enabled boolean DEFAULT false,
    linkding_url text DEFAULT ''::text,
    linkding_api_key text DEFAULT ''::text,
    wallabag_only_url boolean DEFAULT false,
    matrix_bot_enabled boolean DEFAULT false,
    matrix_bot_user text DEFAULT ''::text,
    matrix_bot_password text DEFAULT ''::text,
    matrix_bot_url text DEFAULT ''::text,
    matrix_bot_chat_id text DEFAULT ''::text,
    linkding_tags text DEFAULT ''::text,
    linkding_mark_as_unread boolean DEFAULT false,
    notion_enabled boolean DEFAULT false,
    notion_token text DEFAULT ''::text,
    notion_page_id text DEFAULT ''::text,
    readwise_enabled boolean DEFAULT false,
    readwise_api_key text DEFAULT ''::text,
    apprise_enabled boolean DEFAULT false,
    apprise_url text DEFAULT ''::text,
    apprise_services_url text DEFAULT ''::text,
    shiori_enabled boolean DEFAULT false,
    shiori_url text DEFAULT ''::text,
    shiori_username text DEFAULT ''::text,
    shiori_password text DEFAULT ''::text,
    shaarli_enabled boolean DEFAULT false,
    shaarli_url text DEFAULT ''::text,
    shaarli_api_secret text DEFAULT ''::text,
    webhook_enabled boolean DEFAULT false,
    webhook_url text DEFAULT ''::text,
    webhook_secret text DEFAULT ''::text,
    telegram_bot_topic_id integer,
    telegram_bot_disable_web_page_preview boolean DEFAULT false,
    telegram_bot_disable_notification boolean DEFAULT false,
    telegram_bot_disable_buttons boolean DEFAULT false,
    rssbridge_enabled boolean DEFAULT false,
    rssbridge_url text DEFAULT ''::text,
    omnivore_enabled boolean DEFAULT false,
    omnivore_api_key text DEFAULT ''::text,
    omnivore_url text DEFAULT ''::text,
    linkace_enabled boolean DEFAULT false,
    linkace_url text DEFAULT ''::text,
    linkace_api_key text DEFAULT ''::text,
    linkace_tags text DEFAULT ''::text,
    linkace_is_private boolean DEFAULT true,
    linkace_check_disabled boolean DEFAULT true,
    linkwarden_enabled boolean DEFAULT false,
    linkwarden_url text DEFAULT ''::text,
    linkwarden_api_key text DEFAULT ''::text,
    readeck_enabled boolean DEFAULT false,
    readeck_only_url boolean DEFAULT false,
    readeck_url text DEFAULT ''::text,
    readeck_api_key text DEFAULT ''::text,
    readeck_labels text DEFAULT ''::text,
    raindrop_enabled boolean DEFAULT false,
    raindrop_token text DEFAULT ''::text,
    raindrop_collection_id text DEFAULT ''::text,
    raindrop_tags text DEFAULT ''::text,
    betula_url text DEFAULT ''::text,
    betula_token text DEFAULT ''::text,
    betula_enabled boolean DEFAULT false,
    ntfy_enabled boolean DEFAULT false,
    ntfy_url text DEFAULT ''::text,
    ntfy_topic text DEFAULT ''::text,
    ntfy_api_token text DEFAULT ''::text,
    ntfy_username text DEFAULT ''::text,
    ntfy_password text DEFAULT ''::text,
    ntfy_icon_url text DEFAULT ''::text,
    cubox_enabled boolean DEFAULT false,
    cubox_api_link text DEFAULT ''::text,
    discord_enabled boolean DEFAULT false,
    discord_webhook_link text DEFAULT ''::text,
    ntfy_internal_links boolean DEFAULT false,
    slack_enabled boolean DEFAULT false,
    slack_webhook_link text DEFAULT ''::text,
    pushover_enabled boolean DEFAULT false,
    pushover_user text DEFAULT ''::text,
    pushover_token text DEFAULT ''::text,
    pushover_device text DEFAULT ''::text,
    pushover_prefix text DEFAULT ''::text,
    rssbridge_token text DEFAULT ''::text
);


ALTER TABLE public.integrations OWNER TO miniflux_user;

--
-- Name: schema_version; Type: TABLE; Schema: public; Owner: miniflux_user
--

CREATE TABLE public.schema_version (
    version text NOT NULL
);


ALTER TABLE public.schema_version OWNER TO miniflux_user;

--
-- Name: sessions; Type: TABLE; Schema: public; Owner: miniflux_user
--

CREATE TABLE public.sessions (
    id text NOT NULL,
    data jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.sessions OWNER TO miniflux_user;

--
-- Name: user_sessions; Type: TABLE; Schema: public; Owner: miniflux_user
--

CREATE TABLE public.user_sessions (
    id integer NOT NULL,
    user_id integer NOT NULL,
    token text NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    user_agent text,
    ip inet
);


ALTER TABLE public.user_sessions OWNER TO miniflux_user;

--
-- Name: sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: miniflux_user
--

CREATE SEQUENCE public.sessions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sessions_id_seq OWNER TO miniflux_user;

--
-- Name: sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: miniflux_user
--

ALTER SEQUENCE public.sessions_id_seq OWNED BY public.user_sessions.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: miniflux_user
--

CREATE TABLE public.users (
    id integer NOT NULL,
    username text NOT NULL,
    password text,
    is_admin boolean DEFAULT false,
    language text DEFAULT 'en_US'::text,
    timezone text DEFAULT 'UTC'::text,
    theme text DEFAULT 'light_serif'::text,
    last_login_at timestamp with time zone,
    entry_direction public.entry_sorting_direction DEFAULT 'asc'::public.entry_sorting_direction,
    keyboard_shortcuts boolean DEFAULT true,
    entries_per_page integer DEFAULT 100,
    show_reading_time boolean DEFAULT true,
    entry_swipe boolean DEFAULT true,
    stylesheet text DEFAULT ''::text NOT NULL,
    google_id text DEFAULT ''::text NOT NULL,
    openid_connect_id text DEFAULT ''::text NOT NULL,
    display_mode public.webapp_display_mode DEFAULT 'standalone'::public.webapp_display_mode,
    entry_order public.entry_sorting_order DEFAULT 'published_at'::public.entry_sorting_order,
    default_reading_speed integer DEFAULT 265,
    cjk_reading_speed integer DEFAULT 500,
    default_home_page text DEFAULT 'unread'::text,
    categories_sorting_order text DEFAULT 'unread_count'::text NOT NULL,
    gesture_nav text DEFAULT 'tap'::text,
    mark_read_on_view boolean DEFAULT true,
    media_playback_rate numeric DEFAULT 1,
    block_filter_entry_rules text DEFAULT ''::text NOT NULL,
    keep_filter_entry_rules text DEFAULT ''::text NOT NULL,
    mark_read_on_media_player_completion boolean DEFAULT false,
    custom_js text DEFAULT ''::text NOT NULL,
    external_font_hosts text DEFAULT ''::text NOT NULL,
    always_open_external_links boolean DEFAULT false
);


ALTER TABLE public.users OWNER TO miniflux_user;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: miniflux_user
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_id_seq OWNER TO miniflux_user;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: miniflux_user
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: webauthn_credentials; Type: TABLE; Schema: public; Owner: miniflux_user
--

CREATE TABLE public.webauthn_credentials (
    handle bytea NOT NULL,
    cred_id bytea NOT NULL,
    user_id integer NOT NULL,
    public_key bytea NOT NULL,
    attestation_type character varying(255) NOT NULL,
    aaguid bytea,
    sign_count bigint,
    clone_warning boolean,
    name text,
    added_on timestamp with time zone DEFAULT now(),
    last_seen_on timestamp with time zone DEFAULT now()
);


ALTER TABLE public.webauthn_credentials OWNER TO miniflux_user;

--
-- Name: api_keys id; Type: DEFAULT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.api_keys ALTER COLUMN id SET DEFAULT nextval('public.api_keys_id_seq'::regclass);


--
-- Name: categories id; Type: DEFAULT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.categories ALTER COLUMN id SET DEFAULT nextval('public.categories_id_seq'::regclass);


--
-- Name: enclosures id; Type: DEFAULT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.enclosures ALTER COLUMN id SET DEFAULT nextval('public.enclosures_id_seq'::regclass);


--
-- Name: entries id; Type: DEFAULT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.entries ALTER COLUMN id SET DEFAULT nextval('public.entries_id_seq'::regclass);


--
-- Name: feeds id; Type: DEFAULT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.feeds ALTER COLUMN id SET DEFAULT nextval('public.feeds_id_seq'::regclass);


--
-- Name: icons id; Type: DEFAULT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.icons ALTER COLUMN id SET DEFAULT nextval('public.icons_id_seq'::regclass);


--
-- Name: user_sessions id; Type: DEFAULT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.user_sessions ALTER COLUMN id SET DEFAULT nextval('public.sessions_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Data for Name: acme_cache; Type: TABLE DATA; Schema: public; Owner: miniflux_user
--

COPY public.acme_cache (key, data, updated_at) FROM stdin;
\.


--
-- Data for Name: api_keys; Type: TABLE DATA; Schema: public; Owner: miniflux_user
--

COPY public.api_keys (id, user_id, token, description, last_used_at, created_at) FROM stdin;
\.


--
-- Data for Name: categories; Type: TABLE DATA; Schema: public; Owner: miniflux_user
--

COPY public.categories (id, user_id, title, hide_globally) FROM stdin;
1	1	All	f
2	2	All	f
3	3	All	f
4	4	All	f
5	5	All	f
6	6	All	f
7	7	All	f
8	8	All	f
9	9	All	f
10	10	All	f
11	11	All	f
12	12	All	f
13	13	All	f
14	14	All	f
15	2	Zoo Labs	f
16	2	My projects	f
17	3	Projects	f
18	4	Community	f
19	7	Commits	f
\.


--
-- Data for Name: enclosures; Type: TABLE DATA; Schema: public; Owner: miniflux_user
--

COPY public.enclosures (id, user_id, entry_id, url, size, mime_type, media_progression) FROM stdin;
\.


--
-- Data for Name: entries; Type: TABLE DATA; Schema: public; Owner: miniflux_user
--

COPY public.entries (id, user_id, feed_id, hash, published_at, title, url, author, content, status, starred, comments_url, document_vectors, changed_at, share_code, reading_time, created_at, tags) FROM stdin;
1	2	1	ccc184b67ef507010bbc56cc1fe37c498ae04a13899f40be8e13620d5902eec6	2025-10-09 23:27:55+00	admin created repository <a href="https://gitea.zoo/zoo-labs/zoo-utilities">zoo-labs/zoo-utilities</a>	https://gitea.zoo/zoo-labs/zoo-utilities	admin		unread	f		'/zoo-utilities':7A 'admin':1A 'creat':2A 'lab':6A 'repositori':3A 'zoo':5A 'zoo-lab':4A	2026-09-20 19:32:52.331818+00		0	2026-09-20 19:32:52.331818+00	\N
2	2	1	de27446674769520eedfe0c3246675731ba571ee27d7004f50da4a0fa1204f77	2026-09-01 09:12:00+00	grace opened issue <a href="https://gitea.zoo/zoo-labs/zoo-utilities/issues/1">zoo-labs/zoo-utilities#1</a>	https://gitea.zoo/zoo-labs/zoo-utilities/issues/1	grace	<p><code>lib/auth.js</code> builds tokens from <code>Math.random().toString(36)</code>. The output is predictable and only about 11 characters long, so it shouldn&#39;t be used for session or password reset tokens.</p>\n<p>We should use <code>crypto.randomBytes</code> instead.</p>\n	unread	f		'/zoo-utilities':7A '1':8A '11':23B '36':15B 'build':10B 'charact':24B 'crypto.randombytes':41B 'grace':1A 'instead':42B 'issu':3A 'lab':6A 'lib/auth.js':9B 'long':25B 'math.random':13B 'open':2A 'output':17B 'password':35B 'predict':19B 'reset':36B 'session':33B 'shouldn':28B 'token':11B,37B 'tostr':14B 'use':31B,40B 'zoo':5A 'zoo-lab':4A	2026-09-20 19:32:52.33421+00		1	2026-09-20 19:32:52.33421+00	\N
3	2	1	0c3810e8c2f7c011c1885e990ef1b5ad46105b211977b1d09856430d868b0dac	2026-09-01 10:03:00+00	alice commented on issue <a href="https://gitea.zoo/zoo-labs/zoo-utilities/issues/1">zoo-labs/zoo-utilities#1</a>	https://gitea.zoo/zoo-labs/zoo-utilities/issues/1#issuecomment-12	alice	generateToken uses Math.random, which is not secure\n\n<p>Agreed. I&#39;ll open a PR that switches to <code>crypto.randomBytes(32)</code> and hex-encodes the result.</p>\n	unread	f		'/zoo-utilities':8A '1':9A '32':27B 'agre':17B 'alic':1A 'comment':2A 'crypto.randombytes':26B 'encod':31B 'generatetoken':10B 'hex':30B 'hex-encod':29B 'issu':4A 'lab':7A 'll':19B 'math.random':12B 'open':20B 'pr':22B 'result':33B 'secur':16B 'switch':24B 'use':11B 'zoo':6A 'zoo-lab':5A	2026-09-20 19:32:52.334786+00		1	2026-09-20 19:32:52.334786+00	\N
4	2	1	4801c47f64aa3ce7e86e54cb20e03501f6714375ce46530d3618036e1a80835a	2026-09-02 08:30:00+00	blake.sullivan commented on issue <a href="https://gitea.zoo/zoo-labs/zoo-utilities/issues/1">zoo-labs/zoo-utilities#1</a>	https://gitea.zoo/zoo-labs/zoo-utilities/issues/1#issuecomment-13	blake.sullivan	generateToken uses Math.random, which is not secure\n\n<p>Thanks both. This one blocks v1.3.0.</p>\n	unread	f		'/zoo-utilities':8A '1':9A 'blake.sullivan':1A 'block':21B 'comment':2A 'generatetoken':10B 'issu':4A 'lab':7A 'math.random':12B 'one':20B 'secur':16B 'thank':17B 'use':11B 'v1.3.0':22B 'zoo':6A 'zoo-lab':5A	2026-09-20 19:32:52.335333+00		1	2026-09-20 19:32:52.335333+00	\N
5	2	1	e627e9fb6e00c3490aba4b00cd836d97466461b166a9b0a1a54e634da67cf2dc	2026-09-03 14:20:00+00	alex.chen opened issue <a href="https://gitea.zoo/zoo-labs/zoo-utilities/issues/2">zoo-labs/zoo-utilities#2</a>	https://gitea.zoo/zoo-labs/zoo-utilities/issues/2	alex.chen	<p><code>index.js</code> requires <code>./lib/db</code> and <code>./lib/validators</code>, but neither file is in the repo, so importing the package throws:</p>\n<pre><code>Error: Cannot find module &#39;./lib/db&#39;\n</code></pre><p>Either add the modules or drop them from <code>index.js</code>.</p>\n	unread	f		'./lib/db':11B,30B './lib/validators':13B '/zoo-utilities':7A '2':8A 'add':32B 'alex.chen':1A 'cannot':27B 'drop':36B 'either':31B 'error':26B 'file':16B 'find':28B 'import':22B 'index.js':9B,39B 'issu':3A 'lab':6A 'modul':29B,34B 'neither':15B 'open':2A 'packag':24B 'repo':20B 'requir':10B 'throw':25B 'zoo':5A 'zoo-lab':4A	2026-09-20 19:32:52.335758+00		1	2026-09-20 19:32:52.335758+00	\N
6	2	1	e4aa05346a5cd691cad562bfe464b8701d9b6b870bfb1db9faf9e4b6d3fa0277	2026-09-03 15:02:00+00	bob commented on issue <a href="https://gitea.zoo/zoo-labs/zoo-utilities/issues/2">zoo-labs/zoo-utilities#2</a>	https://gitea.zoo/zoo-labs/zoo-utilities/issues/2#issuecomment-22	bob	require(&#39;@zoo-labs/utilities&#39;) fails: lib/db.js is missing\n\n<p>Confirmed on a clean install. I&#39;d rather add minimal modules than change the exports.</p>\n	unread	f		'/utilities':14B '/zoo-utilities':8A '2':9A 'add':27B 'bob':1A 'chang':31B 'clean':22B 'comment':2A 'confirm':19B 'd':25B 'export':33B 'fail':15B 'instal':23B 'issu':4A 'lab':7A,13B 'lib/db.js':16B 'minim':28B 'miss':18B 'modul':29B 'rather':26B 'requir':10B 'zoo':6A,12B 'zoo-lab':5A,11B	2026-09-20 19:32:52.33616+00		1	2026-09-20 19:32:52.33616+00	\N
7	2	1	4143ad321c482659b96dc39bca70ea91c00f730055d7fc8e7d7c371ae714f06b	2026-09-04 16:40:00+00	eve opened issue <a href="https://gitea.zoo/zoo-labs/zoo-utilities/issues/3">zoo-labs/zoo-utilities#3</a>	https://gitea.zoo/zoo-labs/zoo-utilities/issues/3	eve	<p><code>validateToken(&#39;x&#39;)</code> returns <code>true</code>. I expected it to reject strings that <code>generateToken</code> could never produce.</p>\n	unread	f		'/zoo-utilities':7A '3':8A 'could':21B 'eve':1A 'expect':14B 'generatetoken':20B 'issu':3A 'lab':6A 'never':22B 'open':2A 'produc':23B 'reject':17B 'return':11B 'string':18B 'true':12B 'validatetoken':9B 'x':10B 'zoo':5A 'zoo-lab':4A	2026-09-20 19:32:52.336772+00		1	2026-09-20 19:32:52.336772+00	\N
8	2	1	d9e9e4a86c529be12c0b0aeab5af56fcbaa8c71f1724a15f50e53ebcd2b83faa	2026-09-05 13:40:00+00	alice pushed to <a href="https://gitea.zoo/zoo-labs/zoo-utilities/src/branch/alice/secure-tokens">alice/secure-tokens</a> at <a href="https://gitea.zoo/zoo-labs/zoo-utilities">zoo-labs/zoo-utilities</a>	https://gitea.zoo/zoo-labs/zoo-utilities/commit/8ab025ddf7993b79a8e8d570f557601ec1f04608	alice	<a href="https://gitea.zoo/zoo-labs/zoo-utilities/commit/8ab025ddf7993b79a8e8d570f557601ec1f04608" rel="noopener noreferrer" target="_blank" referrerpolicy="no-referrer">8ab025ddf7993b79a8e8d570f557601ec1f04608</a>\nGenerate auth tokens with crypto.randomBytes	unread	f		'/zoo-utilities':9A '8ab025ddf7993b79a8e8d570f557601ec1f04608':10B 'alic':1A 'alice/secure-tokens':4A 'auth':12B 'crypto.randombytes':15B 'generat':11B 'lab':8A 'push':2A 'token':13B 'zoo':7A 'zoo-lab':6A	2026-09-20 19:32:52.337404+00		1	2026-09-20 19:32:52.337404+00	\N
9	2	1	5a0f5d34e173ab80e9cb605573ee4dc9af59de30773be7c41dae5d2bd9d7fbe2	2026-09-05 13:40:00+00	alice created branch <a href="https://gitea.zoo/zoo-labs/zoo-utilities/src/branch/alice/secure-tokens">alice/secure-tokens</a> in <a href="https://gitea.zoo/zoo-labs/zoo-utilities">zoo-labs/zoo-utilities</a>	https://gitea.zoo/zoo-labs/zoo-utilities/src/branch/alice/secure-tokens	alice		unread	f		'/zoo-utilities':9A 'alic':1A 'alice/secure-tokens':4A 'branch':3A 'creat':2A 'lab':8A 'zoo':7A 'zoo-lab':6A	2026-09-20 19:32:52.337819+00		0	2026-09-20 19:32:52.337819+00	\N
10	2	1	c260b57ac8c77d2675bc0d1a2e0c763f31b21fb01219b5c750aedf72638d017d	2026-09-05 13:52:00+00	alice created pull request <a href="https://gitea.zoo/zoo-labs/zoo-utilities/pulls/4">zoo-labs/zoo-utilities#4</a>	https://gitea.zoo/zoo-labs/zoo-utilities/pulls/4	alice	<p>Fixes <a href="https://gitea.zoo/zoo-labs/zoo-utilities/issues/1" rel="noopener noreferrer" target="_blank" referrerpolicy="no-referrer">#1</a>.</p>\n<ul>\n<li><code>generateToken</code> returns 32 random bytes, hex-encoded</li>\n<li><code>validateToken</code> accepts only 64 hex characters</li>\n</ul>\n	unread	f		'/zoo-utilities':8A '1':11B '32':14B '4':9A '64':23B 'accept':21B 'alic':1A 'byte':16B 'charact':25B 'creat':2A 'encod':19B 'fix':10B 'generatetoken':12B 'hex':18B,24B 'hex-encod':17B 'lab':7A 'pull':3A 'random':15B 'request':4A 'return':13B 'validatetoken':20B 'zoo':6A 'zoo-lab':5A	2026-09-20 19:32:52.338266+00		1	2026-09-20 19:32:52.338266+00	\N
11	2	1	baa4e35dbfb2df4a5e95e3294277c7100e7288b1e37af3e363ab3ecb2cea3a5b	2026-09-05 14:05:00+00	alice commented on issue <a href="https://gitea.zoo/zoo-labs/zoo-utilities/issues/3">zoo-labs/zoo-utilities#3</a>	https://gitea.zoo/zoo-labs/zoo-utilities/issues/3#issuecomment-31	alice	validateToken accepts any non-empty string\n\n<p>Same root cause as <a href="https://gitea.zoo/zoo-labs/zoo-utilities/issues/1" rel="noopener noreferrer" target="_blank" referrerpolicy="no-referrer">#1</a>: tokens have no fixed format yet. <a href="https://gitea.zoo/zoo-labs/zoo-utilities/issues/4" rel="noopener noreferrer" target="_blank" referrerpolicy="no-referrer">#4</a> makes them 64 hex characters and checks for exactly that, so I&#39;m closing this as a duplicate.</p>\n	unread	f		'/zoo-utilities':8A '1':21B '3':9A '4':28B '64':31B 'accept':11B 'alic':1A 'caus':19B 'charact':33B 'check':35B 'close':42B 'comment':2A 'duplic':46B 'empti':15B 'exact':37B 'fix':25B 'format':26B 'hex':32B 'issu':4A 'lab':7A 'm':41B 'make':29B 'non':14B 'non-empti':13B 'root':18B 'string':16B 'token':22B 'validatetoken':10B 'yet':27B 'zoo':6A 'zoo-lab':5A	2026-09-20 19:32:52.33875+00		1	2026-09-20 19:32:52.33875+00	\N
12	2	1	d45d7e55a90e365f0a56598338927c0950144de83da7846f2e416d5e34ebc3af	2026-09-05 14:06:00+00	alice closed issue <a href="https://gitea.zoo/zoo-labs/zoo-utilities/issues/3">zoo-labs/zoo-utilities#3</a>	https://gitea.zoo/zoo-labs/zoo-utilities/issues/3#issuecomment-34	alice	validateToken accepts any non-empty string	unread	f		'/zoo-utilities':7A '3':8A 'accept':10B 'alic':1A 'close':2A 'empti':14B 'issu':3A 'lab':6A 'non':13B 'non-empti':12B 'string':15B 'validatetoken':9B 'zoo':5A 'zoo-lab':4A	2026-09-20 19:32:52.339198+00		1	2026-09-20 19:32:52.339198+00	\N
13	2	1	7c3aa33924e2018e77b858ff724c0aa1b773d9cfc60ae948e50d7cd242791fd7	2026-09-07 09:05:00+00	grace commented on pull request <a href="https://gitea.zoo/zoo-labs/zoo-utilities/pulls/4">zoo-labs/zoo-utilities#4</a>	https://gitea.zoo/zoo-labs/zoo-utilities/pulls/4#issuecomment-37	grace	Generate auth tokens with crypto.randomBytes\n\n<p>Could the byte count be an argument? The invite links in zoo-api-client want shorter tokens.</p>\n	unread	f		'/zoo-utilities':9A '4':10A 'api':29B 'argument':22B 'auth':12B 'byte':18B 'client':30B 'comment':2A 'could':16B 'count':19B 'crypto.randombytes':15B 'generat':11B 'grace':1A 'invit':24B 'lab':8A 'link':25B 'pull':4A 'request':5A 'shorter':32B 'token':13B,33B 'want':31B 'zoo':7A,28B 'zoo-api-cli':27B 'zoo-lab':6A	2026-09-20 19:32:52.339909+00		1	2026-09-20 19:32:52.339909+00	\N
14	2	1	9022315a01fe8c5431a1e9094b0ab5435b831e4f1a38a0a8957c069d3897b79c	2026-09-07 09:05:00+00	grace commented on pull request <a href="https://gitea.zoo/zoo-labs/zoo-utilities/pulls/4">zoo-labs/zoo-utilities#4</a>	https://gitea.zoo/zoo-labs/zoo-utilities/pulls/4#issuecomment-38	grace	Generate auth tokens with crypto.randomBytes\n\n<p>Looks good to me, one question inline.</p>\n	unread	f		'/zoo-utilities':9A '4':10A 'auth':12B 'comment':2A 'crypto.randombytes':15B 'generat':11B 'good':17B 'grace':1A 'inlin':22B 'lab':8A 'look':16B 'one':20B 'pull':4A 'question':21B 'request':5A 'token':13B 'zoo':7A 'zoo-lab':6A	2026-09-20 19:32:52.340608+00		1	2026-09-20 19:32:52.340608+00	\N
15	2	1	901d9e78c4f5a29a0f2866e5aedfee23569464397348d148d3affd08fe575980	2026-09-07 11:30:00+00	alice commented on pull request <a href="https://gitea.zoo/zoo-labs/zoo-utilities/pulls/4">zoo-labs/zoo-utilities#4</a>	https://gitea.zoo/zoo-labs/zoo-utilities/pulls/4#issuecomment-39	alice	Generate auth tokens with crypto.randomBytes\n\n<p>Good idea. I&#39;ll add an optional <code>bytes</code> argument that defaults to 32.</p>\n	unread	f		'/zoo-utilities':9A '32':28B '4':10A 'add':20B 'alic':1A 'argument':24B 'auth':12B 'byte':23B 'comment':2A 'crypto.randombytes':15B 'default':26B 'generat':11B 'good':16B 'idea':17B 'lab':8A 'll':19B 'option':22B 'pull':4A 'request':5A 'token':13B 'zoo':7A 'zoo-lab':6A	2026-09-20 19:32:52.341057+00		1	2026-09-20 19:32:52.341057+00	\N
16	2	2	c0f6ecb3e260089101db7f5e631a711b29b3250ba684ae1a027530644536d9ea	2025-10-09 23:27:54+00	admin created repository <a href="https://gitea.zoo/zoo-labs/commander-mirror">zoo-labs/commander-mirror</a>	https://gitea.zoo/zoo-labs/commander-mirror	admin		unread	f		'/commander-mirror':7A 'admin':1A 'creat':2A 'lab':6A 'repositori':3A 'zoo':5A 'zoo-lab':4A	2026-09-20 19:32:52.411685+00		0	2026-09-20 19:32:52.411685+00	\N
17	2	2	063c7ad33cb9e95b2ae4f1f730d80f58338d2b4b4be4dfffcc809977772fde12	2025-10-09 23:27:55+00	admin created repository <a href="https://gitea.zoo/zoo-labs/zoo-utilities">zoo-labs/zoo-utilities</a>	https://gitea.zoo/zoo-labs/zoo-utilities	admin		unread	f		'/zoo-utilities':7A 'admin':1A 'creat':2A 'lab':6A 'repositori':3A 'zoo':5A 'zoo-lab':4A	2026-09-20 19:32:52.412219+00		0	2026-09-20 19:32:52.412219+00	\N
18	2	2	e8105b1c4e69dc84f076ccbba20d5723ee5954d36b3f0d42adb9749f23fb7b35	2026-09-01 09:12:00+00	grace opened issue <a href="https://gitea.zoo/zoo-labs/zoo-utilities/issues/1">zoo-labs/zoo-utilities#1</a>	https://gitea.zoo/zoo-labs/zoo-utilities/issues/1	grace	<p><code>lib/auth.js</code> builds tokens from <code>Math.random().toString(36)</code>. The output is predictable and only about 11 characters long, so it shouldn&#39;t be used for session or password reset tokens.</p>\n<p>We should use <code>crypto.randomBytes</code> instead.</p>\n	unread	f		'/zoo-utilities':7A '1':8A '11':23B '36':15B 'build':10B 'charact':24B 'crypto.randombytes':41B 'grace':1A 'instead':42B 'issu':3A 'lab':6A 'lib/auth.js':9B 'long':25B 'math.random':13B 'open':2A 'output':17B 'password':35B 'predict':19B 'reset':36B 'session':33B 'shouldn':28B 'token':11B,37B 'tostr':14B 'use':31B,40B 'zoo':5A 'zoo-lab':4A	2026-09-20 19:32:52.412876+00		1	2026-09-20 19:32:52.412876+00	\N
19	2	2	037847030e3e04eb84bc34e7e35450569a49967f491c8901adc07c721c6b4703	2026-09-01 10:03:00+00	alice commented on issue <a href="https://gitea.zoo/zoo-labs/zoo-utilities/issues/1">zoo-labs/zoo-utilities#1</a>	https://gitea.zoo/zoo-labs/zoo-utilities/issues/1#issuecomment-12	alice	generateToken uses Math.random, which is not secure\n\n<p>Agreed. I&#39;ll open a PR that switches to <code>crypto.randomBytes(32)</code> and hex-encodes the result.</p>\n	unread	f		'/zoo-utilities':8A '1':9A '32':27B 'agre':17B 'alic':1A 'comment':2A 'crypto.randombytes':26B 'encod':31B 'generatetoken':10B 'hex':30B 'hex-encod':29B 'issu':4A 'lab':7A 'll':19B 'math.random':12B 'open':20B 'pr':22B 'result':33B 'secur':16B 'switch':24B 'use':11B 'zoo':6A 'zoo-lab':5A	2026-09-20 19:32:52.41339+00		1	2026-09-20 19:32:52.41339+00	\N
20	2	2	6c7b448198c090faf1ec2ab4a2b0a439a135b52c9a93f28d9bc5bb05e1060378	2026-09-02 08:30:00+00	blake.sullivan commented on issue <a href="https://gitea.zoo/zoo-labs/zoo-utilities/issues/1">zoo-labs/zoo-utilities#1</a>	https://gitea.zoo/zoo-labs/zoo-utilities/issues/1#issuecomment-13	blake.sullivan	generateToken uses Math.random, which is not secure\n\n<p>Thanks both. This one blocks v1.3.0.</p>\n	unread	f		'/zoo-utilities':8A '1':9A 'blake.sullivan':1A 'block':21B 'comment':2A 'generatetoken':10B 'issu':4A 'lab':7A 'math.random':12B 'one':20B 'secur':16B 'thank':17B 'use':11B 'v1.3.0':22B 'zoo':6A 'zoo-lab':5A	2026-09-20 19:32:52.413988+00		1	2026-09-20 19:32:52.413988+00	\N
21	2	2	448fd60aefabd49921396820f4941235e14cbbac2cb5ac4ecaea06a3a10638ae	2026-09-03 14:20:00+00	alex.chen opened issue <a href="https://gitea.zoo/zoo-labs/zoo-utilities/issues/2">zoo-labs/zoo-utilities#2</a>	https://gitea.zoo/zoo-labs/zoo-utilities/issues/2	alex.chen	<p><code>index.js</code> requires <code>./lib/db</code> and <code>./lib/validators</code>, but neither file is in the repo, so importing the package throws:</p>\n<pre><code>Error: Cannot find module &#39;./lib/db&#39;\n</code></pre><p>Either add the modules or drop them from <code>index.js</code>.</p>\n	unread	f		'./lib/db':11B,30B './lib/validators':13B '/zoo-utilities':7A '2':8A 'add':32B 'alex.chen':1A 'cannot':27B 'drop':36B 'either':31B 'error':26B 'file':16B 'find':28B 'import':22B 'index.js':9B,39B 'issu':3A 'lab':6A 'modul':29B,34B 'neither':15B 'open':2A 'packag':24B 'repo':20B 'requir':10B 'throw':25B 'zoo':5A 'zoo-lab':4A	2026-09-20 19:32:52.414562+00		1	2026-09-20 19:32:52.414562+00	\N
22	2	2	4d9ee9a67a361f765635372de102ac592ad8822974138c2f20bac4944d885bb9	2026-09-03 15:02:00+00	bob commented on issue <a href="https://gitea.zoo/zoo-labs/zoo-utilities/issues/2">zoo-labs/zoo-utilities#2</a>	https://gitea.zoo/zoo-labs/zoo-utilities/issues/2#issuecomment-22	bob	require(&#39;@zoo-labs/utilities&#39;) fails: lib/db.js is missing\n\n<p>Confirmed on a clean install. I&#39;d rather add minimal modules than change the exports.</p>\n	unread	f		'/utilities':14B '/zoo-utilities':8A '2':9A 'add':27B 'bob':1A 'chang':31B 'clean':22B 'comment':2A 'confirm':19B 'd':25B 'export':33B 'fail':15B 'instal':23B 'issu':4A 'lab':7A,13B 'lib/db.js':16B 'minim':28B 'miss':18B 'modul':29B 'rather':26B 'requir':10B 'zoo':6A,12B 'zoo-lab':5A,11B	2026-09-20 19:32:52.415027+00		1	2026-09-20 19:32:52.415027+00	\N
23	2	2	32e54d95aec897d2dadd278ecf982f28b80e8e8b0e3948173d19c0cb271cb80c	2026-09-04 16:40:00+00	eve opened issue <a href="https://gitea.zoo/zoo-labs/zoo-utilities/issues/3">zoo-labs/zoo-utilities#3</a>	https://gitea.zoo/zoo-labs/zoo-utilities/issues/3	eve	<p><code>validateToken(&#39;x&#39;)</code> returns <code>true</code>. I expected it to reject strings that <code>generateToken</code> could never produce.</p>\n	unread	f		'/zoo-utilities':7A '3':8A 'could':21B 'eve':1A 'expect':14B 'generatetoken':20B 'issu':3A 'lab':6A 'never':22B 'open':2A 'produc':23B 'reject':17B 'return':11B 'string':18B 'true':12B 'validatetoken':9B 'x':10B 'zoo':5A 'zoo-lab':4A	2026-09-20 19:32:52.415437+00		1	2026-09-20 19:32:52.415437+00	\N
24	2	2	363412cc01a79f778e0ac848d1191fcfafc31c99d9f82bc5895d8bc842e2c4d4	2026-09-05 13:40:00+00	alice created branch <a href="https://gitea.zoo/zoo-labs/zoo-utilities/src/branch/alice/secure-tokens">alice/secure-tokens</a> in <a href="https://gitea.zoo/zoo-labs/zoo-utilities">zoo-labs/zoo-utilities</a>	https://gitea.zoo/zoo-labs/zoo-utilities/src/branch/alice/secure-tokens	alice		unread	f		'/zoo-utilities':9A 'alic':1A 'alice/secure-tokens':4A 'branch':3A 'creat':2A 'lab':8A 'zoo':7A 'zoo-lab':6A	2026-09-20 19:32:52.415855+00		0	2026-09-20 19:32:52.415855+00	\N
25	2	2	50fe38abed5186bf304bae38da410d8be3d1d29e41c3ae4f4fe14e172830e48d	2026-09-05 13:40:00+00	alice pushed to <a href="https://gitea.zoo/zoo-labs/zoo-utilities/src/branch/alice/secure-tokens">alice/secure-tokens</a> at <a href="https://gitea.zoo/zoo-labs/zoo-utilities">zoo-labs/zoo-utilities</a>	https://gitea.zoo/zoo-labs/zoo-utilities/commit/8ab025ddf7993b79a8e8d570f557601ec1f04608	alice	<a href="https://gitea.zoo/zoo-labs/zoo-utilities/commit/8ab025ddf7993b79a8e8d570f557601ec1f04608" rel="noopener noreferrer" target="_blank" referrerpolicy="no-referrer">8ab025ddf7993b79a8e8d570f557601ec1f04608</a>\nGenerate auth tokens with crypto.randomBytes	unread	f		'/zoo-utilities':9A '8ab025ddf7993b79a8e8d570f557601ec1f04608':10B 'alic':1A 'alice/secure-tokens':4A 'auth':12B 'crypto.randombytes':15B 'generat':11B 'lab':8A 'push':2A 'token':13B 'zoo':7A 'zoo-lab':6A	2026-09-20 19:32:52.416288+00		1	2026-09-20 19:32:52.416288+00	\N
26	2	2	d663f3126e5c9c670248df014b1ce548b16f81c433811e1d2e234d30acc13a3f	2026-09-05 13:52:00+00	alice created pull request <a href="https://gitea.zoo/zoo-labs/zoo-utilities/pulls/4">zoo-labs/zoo-utilities#4</a>	https://gitea.zoo/zoo-labs/zoo-utilities/pulls/4	alice	<p>Fixes <a href="https://gitea.zoo/zoo-labs/zoo-utilities/issues/1" rel="noopener noreferrer" target="_blank" referrerpolicy="no-referrer">#1</a>.</p>\n<ul>\n<li><code>generateToken</code> returns 32 random bytes, hex-encoded</li>\n<li><code>validateToken</code> accepts only 64 hex characters</li>\n</ul>\n	unread	f		'/zoo-utilities':8A '1':11B '32':14B '4':9A '64':23B 'accept':21B 'alic':1A 'byte':16B 'charact':25B 'creat':2A 'encod':19B 'fix':10B 'generatetoken':12B 'hex':18B,24B 'hex-encod':17B 'lab':7A 'pull':3A 'random':15B 'request':4A 'return':13B 'validatetoken':20B 'zoo':6A 'zoo-lab':5A	2026-09-20 19:32:52.416819+00		1	2026-09-20 19:32:52.416819+00	\N
27	2	2	cd95ec04849d734e020ed69ca1ee52d9337502050728aa5997bda76bcfd8f3f8	2026-09-05 14:05:00+00	alice commented on issue <a href="https://gitea.zoo/zoo-labs/zoo-utilities/issues/3">zoo-labs/zoo-utilities#3</a>	https://gitea.zoo/zoo-labs/zoo-utilities/issues/3#issuecomment-31	alice	validateToken accepts any non-empty string\n\n<p>Same root cause as <a href="https://gitea.zoo/zoo-labs/zoo-utilities/issues/1" rel="noopener noreferrer" target="_blank" referrerpolicy="no-referrer">#1</a>: tokens have no fixed format yet. <a href="https://gitea.zoo/zoo-labs/zoo-utilities/issues/4" rel="noopener noreferrer" target="_blank" referrerpolicy="no-referrer">#4</a> makes them 64 hex characters and checks for exactly that, so I&#39;m closing this as a duplicate.</p>\n	unread	f		'/zoo-utilities':8A '1':21B '3':9A '4':28B '64':31B 'accept':11B 'alic':1A 'caus':19B 'charact':33B 'check':35B 'close':42B 'comment':2A 'duplic':46B 'empti':15B 'exact':37B 'fix':25B 'format':26B 'hex':32B 'issu':4A 'lab':7A 'm':41B 'make':29B 'non':14B 'non-empti':13B 'root':18B 'string':16B 'token':22B 'validatetoken':10B 'yet':27B 'zoo':6A 'zoo-lab':5A	2026-09-20 19:32:52.417228+00		1	2026-09-20 19:32:52.417228+00	\N
28	2	2	acd83fe5572ed9a6025f95b08fe00eeef255f33f484e7cbe22196e5e8955bad8	2026-09-05 14:06:00+00	alice closed issue <a href="https://gitea.zoo/zoo-labs/zoo-utilities/issues/3">zoo-labs/zoo-utilities#3</a>	https://gitea.zoo/zoo-labs/zoo-utilities/issues/3#issuecomment-34	alice	validateToken accepts any non-empty string	unread	f		'/zoo-utilities':7A '3':8A 'accept':10B 'alic':1A 'close':2A 'empti':14B 'issu':3A 'lab':6A 'non':13B 'non-empti':12B 'string':15B 'validatetoken':9B 'zoo':5A 'zoo-lab':4A	2026-09-20 19:32:52.417644+00		1	2026-09-20 19:32:52.417644+00	\N
29	2	2	e5a9f96d73024e7b2ad31d73298836220f1b7019fe5d62c28051e58ed71a8460	2026-09-07 09:05:00+00	grace commented on pull request <a href="https://gitea.zoo/zoo-labs/zoo-utilities/pulls/4">zoo-labs/zoo-utilities#4</a>	https://gitea.zoo/zoo-labs/zoo-utilities/pulls/4#issuecomment-38	grace	Generate auth tokens with crypto.randomBytes\n\n<p>Looks good to me, one question inline.</p>\n	unread	f		'/zoo-utilities':9A '4':10A 'auth':12B 'comment':2A 'crypto.randombytes':15B 'generat':11B 'good':17B 'grace':1A 'inlin':22B 'lab':8A 'look':16B 'one':20B 'pull':4A 'question':21B 'request':5A 'token':13B 'zoo':7A 'zoo-lab':6A	2026-09-20 19:32:52.418032+00		1	2026-09-20 19:32:52.418032+00	\N
30	2	2	c68a1068342e7577b6560dbc14ee782cbb439040708cb3ae606f5080861cbd45	2026-09-07 09:05:00+00	grace commented on pull request <a href="https://gitea.zoo/zoo-labs/zoo-utilities/pulls/4">zoo-labs/zoo-utilities#4</a>	https://gitea.zoo/zoo-labs/zoo-utilities/pulls/4#issuecomment-37	grace	Generate auth tokens with crypto.randomBytes\n\n<p>Could the byte count be an argument? The invite links in zoo-api-client want shorter tokens.</p>\n	unread	f		'/zoo-utilities':9A '4':10A 'api':29B 'argument':22B 'auth':12B 'byte':18B 'client':30B 'comment':2A 'could':16B 'count':19B 'crypto.randombytes':15B 'generat':11B 'grace':1A 'invit':24B 'lab':8A 'link':25B 'pull':4A 'request':5A 'shorter':32B 'token':13B,33B 'want':31B 'zoo':7A,28B 'zoo-api-cli':27B 'zoo-lab':6A	2026-09-20 19:32:52.41844+00		1	2026-09-20 19:32:52.41844+00	\N
31	2	2	e29d5f60379795658dacd98f5395de32c1b0f182e64e018bad061234b903f512	2026-09-07 11:30:00+00	alice commented on pull request <a href="https://gitea.zoo/zoo-labs/zoo-utilities/pulls/4">zoo-labs/zoo-utilities#4</a>	https://gitea.zoo/zoo-labs/zoo-utilities/pulls/4#issuecomment-39	alice	Generate auth tokens with crypto.randomBytes\n\n<p>Good idea. I&#39;ll add an optional <code>bytes</code> argument that defaults to 32.</p>\n	unread	f		'/zoo-utilities':9A '32':28B '4':10A 'add':20B 'alic':1A 'argument':24B 'auth':12B 'byte':23B 'comment':2A 'crypto.randombytes':15B 'default':26B 'generat':11B 'good':16B 'idea':17B 'lab':8A 'll':19B 'option':22B 'pull':4A 'request':5A 'token':13B 'zoo':7A 'zoo-lab':6A	2026-09-20 19:32:52.418857+00		1	2026-09-20 19:32:52.418857+00	\N
32	2	3	99702ea124b39ea557a17120a2fcd65f7d17dde6423bc76a1ac50322d8e6d05d	2025-10-09 23:27:56+00	alice created repository <a href="https://gitea.zoo/alice/hello-zoo">alice/hello-zoo</a>	https://gitea.zoo/alice/hello-zoo	alice		unread	f		'alic':1A 'alice/hello-zoo':4A 'creat':2A 'repositori':3A	2026-09-20 19:32:52.654152+00		0	2026-09-20 19:32:52.654152+00	\N
33	2	3	f83c431bd6cab824a57b6e3bacf0cb07b4231fb49be02c169b9f150f98510b8c	2026-08-24 10:15:00+00	frank opened issue <a href="https://gitea.zoo/alice/hello-zoo/issues/1">alice/hello-zoo#1</a>	https://gitea.zoo/alice/hello-zoo/issues/1	frank	<p><code>index.js</code> hard-codes port 3000, which clashes with other services when we run it in a container. Could it use <code>process.env.PORT</code> and fall back to 3000?</p>\n	unread	f		'1':5A '3000':11B,32B 'alice/hello-zoo':4A 'back':30B 'clash':13B 'code':9B 'contain':23B 'could':24B 'fall':29B 'frank':1A 'hard':8B 'hard-cod':7B 'index.js':6B 'issu':3A 'open':2A 'port':10B 'process.env.port':27B 'run':19B 'servic':16B 'use':26B	2026-09-20 19:32:52.654866+00		1	2026-09-20 19:32:52.654866+00	\N
34	2	3	65b3f39489842cb2c2c621f472c0f93e9c0298fe00a490951ff5d1545780a7d3	2026-08-24 12:40:00+00	alice commented on issue <a href="https://gitea.zoo/alice/hello-zoo/issues/1">alice/hello-zoo#1</a>	https://gitea.zoo/alice/hello-zoo/issues/1#issuecomment-3	alice	Read the port from the PORT environment variable\n\n<p>Makes sense. Happy to take a PR for this one.</p>\n	unread	f		'1':6A 'alic':1A 'alice/hello-zoo':5A 'comment':2A 'environ':13B 'happi':17B 'issu':4A 'make':15B 'one':24B 'port':9B,12B 'pr':21B 'read':7B 'sens':16B 'take':19B 'variabl':14B	2026-09-20 19:32:52.65556+00		1	2026-09-20 19:32:52.65556+00	\N
35	2	3	68587382298b1d9c5057b081e225dc9b0c6bd51f8d9b2bfcecf7bd66535f1cc4	2026-08-28 15:30:00+00	diana opened issue <a href="https://gitea.zoo/alice/hello-zoo/issues/2">alice/hello-zoo#2</a>	https://gitea.zoo/alice/hello-zoo/issues/2	diana	<p>The README promises a zoo-themed welcome page, but <code>/</code> returns a bare <code>&lt;h1&gt;</code> with no <code>&lt;title&gt;</code>. I can put together a simple layout with the zoo colors if that&#39;s welcome.</p>\n	unread	f		'2':5A 'alice/hello-zoo':4A 'bare':18B 'color':33B 'diana':1A 'h1':19B 'issu':3A 'layout':29B 'open':2A 'page':14B 'promis':8B 'put':25B 'readm':7B 'return':16B 'simpl':28B 'theme':12B 'titl':22B 'togeth':26B 'welcom':13B,37B 'zoo':11B,32B 'zoo-them':10B	2026-09-20 19:32:52.656242+00		1	2026-09-20 19:32:52.656242+00	\N
36	2	3	c2f556fe115796c41a7b74f686cd3aa8d2e448345ae02dabd52a82b404cfd054	2026-08-28 17:05:00+00	alice commented on issue <a href="https://gitea.zoo/alice/hello-zoo/issues/2">alice/hello-zoo#2</a>	https://gitea.zoo/alice/hello-zoo/issues/2#issuecomment-5	alice	The welcome page has no styling or title\n\n<p>Yes please! Keep it to a single HTML string in <code>index.js</code> for now.</p>\n	unread	f		'2':6A 'alic':1A 'alice/hello-zoo':5A 'comment':2A 'html':22B 'index.js':25B 'issu':4A 'keep':17B 'page':9B 'pleas':16B 'singl':21B 'string':23B 'style':12B 'titl':14B 'welcom':8B 'yes':15B	2026-09-20 19:32:52.656893+00		1	2026-09-20 19:32:52.656893+00	\N
37	2	3	ea65b7198160c985b4a038b729f532ebb87abbb743ab00c08972236dbd77b906	2026-09-11 11:20:00+00	user1 opened issue <a href="https://gitea.zoo/alice/hello-zoo/issues/3">alice/hello-zoo#3</a>	https://gitea.zoo/alice/hello-zoo/issues/3	user1	<p>Port 3000 is taken on my machine. Is there a flag for the port?</p>\n	unread	f		'3':5A '3000':7B 'alice/hello-zoo':4A 'flag':16B 'issu':3A 'machin':12B 'open':2A 'port':6B,19B 'taken':9B 'user1':1A	2026-09-20 19:32:52.657492+00		1	2026-09-20 19:32:52.657492+00	\N
38	2	3	89757838b8c14448ce3c633c2e2a9b5ed9574151effda1df109924a75ef6f341	2026-09-11 13:00:00+00	alice commented on issue <a href="https://gitea.zoo/alice/hello-zoo/issues/3">alice/hello-zoo#3</a>	https://gitea.zoo/alice/hello-zoo/issues/3#issuecomment-45	alice	How do I run this on a different port?\n\n<p>Not yet: change <code>port</code> in <code>index.js</code> for now. <a href="https://gitea.zoo/alice/hello-zoo/issues/1" rel="noopener noreferrer" target="_blank" referrerpolicy="no-referrer">#1</a> tracks reading it from <code>PORT</code>, so I&#39;m closing this one.</p>\n	unread	f		'1':24B '3':6A 'alic':1A 'alice/hello-zoo':5A 'chang':18B 'close':33B 'comment':2A 'differ':14B 'index.js':21B 'issu':4A 'm':32B 'one':35B 'port':15B,19B,29B 'read':26B 'run':10B 'track':25B 'yet':17B	2026-09-20 19:32:52.658041+00		1	2026-09-20 19:32:52.658041+00	\N
39	2	3	87b1708ccdb5c422375b07894e87e43537cc378525625b87fff1d6fc09ef2b42	2026-09-11 13:01:00+00	alice closed issue <a href="https://gitea.zoo/alice/hello-zoo/issues/3">alice/hello-zoo#3</a>	https://gitea.zoo/alice/hello-zoo/issues/3#issuecomment-47	alice	How do I run this on a different port?	unread	f		'3':5A 'alic':1A 'alice/hello-zoo':4A 'close':2A 'differ':13B 'issu':3A 'port':14B 'run':9B	2026-09-20 19:32:52.658654+00		1	2026-09-20 19:32:52.658654+00	\N
40	3	4	0015e2250ccc979f70cf365f78b9b056632e9e5975c2f8ab9f66ace13800a5b0	2025-10-09 23:27:50+00	bob created repository <a href="https://gitea.zoo/bob/zoo-api-client">bob/zoo-api-client</a>	https://gitea.zoo/bob/zoo-api-client	bob		unread	f		'bob':1A 'bob/zoo-api-client':4A 'creat':2A 'repositori':3A	2026-09-20 19:32:52.890088+00		0	2026-09-20 19:32:52.890088+00	\N
41	3	4	7b1f6bfc3907f7da9a3c1e57d3270667f4e4a20974c960d3bad11b6bbb6619b9	2026-09-02 13:05:00+00	charlie opened issue <a href="https://gitea.zoo/bob/zoo-api-client/issues/1">bob/zoo-api-client#1</a>	https://gitea.zoo/bob/zoo-api-client/issues/1	charlie	<p>When misc.zoo answers with a 500, <code>getAnimals()</code> calls <code>response.json()</code> on the error page and throws a <code>SyntaxError</code>, which hides the real problem. It should check <code>response.ok</code> and throw an error that includes the status.</p>\n	unread	f		'1':5A '500':11B 'answer':8B 'bob/zoo-api-client':4A 'call':13B 'charli':1A 'check':30B 'error':17B,35B 'getanim':12B 'hide':24B 'includ':37B 'issu':3A 'misc.zoo':7B 'open':2A 'page':18B 'problem':27B 'real':26B 'response.json':14B 'response.ok':31B 'status':39B 'syntaxerror':22B 'throw':20B,33B	2026-09-20 19:32:52.890678+00		1	2026-09-20 19:32:52.890678+00	\N
42	3	4	39cef3a81e12e59309e3a9d5ec7c2290d1931531335c63cb45a06334549995d8	2026-09-02 16:10:00+00	bob commented on issue <a href="https://gitea.zoo/bob/zoo-api-client/issues/1">bob/zoo-api-client#1</a>	https://gitea.zoo/bob/zoo-api-client/issues/1#issuecomment-17	bob	getAnimals() doesn&#39;t check the response status\n\n<p>Good catch. I&#39;ll add an <code>ApiError</code> class with <code>status</code> and <code>url</code>.</p>\n	unread	f		'1':6A 'add':18B 'apierror':20B 'bob':1A 'bob/zoo-api-client':5A 'catch':15B 'check':10B 'class':21B 'comment':2A 'doesn':8B 'getanim':7B 'good':14B 'issu':4A 'll':17B 'respons':12B 'status':13B,23B 'url':25B	2026-09-20 19:32:52.891264+00		1	2026-09-20 19:32:52.891264+00	\N
43	3	4	8c0b48241996fb199f2f841da182afefe4e15d1aa6632ef6870a4fb6d78e7245	2026-09-03 09:00:00+00	alex.chen commented on issue <a href="https://gitea.zoo/bob/zoo-api-client/issues/1">bob/zoo-api-client#1</a>	https://gitea.zoo/bob/zoo-api-client/issues/1#issuecomment-18	alex.chen	getAnimals() doesn&#39;t check the response status\n\n<p>+1. Please include the response body too; misc.zoo returns its errors as JSON.</p>\n	unread	f		'+1':14B '1':6A 'alex.chen':1A 'bob/zoo-api-client':5A 'bodi':19B 'check':10B 'comment':2A 'doesn':8B 'error':24B 'getanim':7B 'includ':16B 'issu':4A 'json':26B 'misc.zoo':21B 'pleas':15B 'respons':12B,18B 'return':22B 'status':13B	2026-09-20 19:32:52.891907+00		1	2026-09-20 19:32:52.891907+00	\N
44	3	4	d415d803a11039fda6c86be2be7ded03ddc8754c889837b7ad4deb8c2b3c13f5	2026-09-04 10:30:00+00	alex.chen opened issue <a href="https://gitea.zoo/bob/zoo-api-client/issues/2">bob/zoo-api-client#2</a>	https://gitea.zoo/bob/zoo-api-client/issues/2	alex.chen	<p>Requests to a stopped service hang until the OS gives up. A <code>timeout</code> option in the <code>ZooClient</code> config, passed to an <code>AbortController</code>, would let callers fail fast.</p>\n	unread	f		'2':5A 'abortcontrol':27B 'alex.chen':1A 'bob/zoo-api-client':4A 'caller':30B 'config':23B 'fail':31B 'fast':32B 'give':15B 'hang':11B 'issu':3A 'let':29B 'open':2A 'option':19B 'os':14B 'pass':24B 'request':6B 'servic':10B 'stop':9B 'timeout':18B 'would':28B 'zooclient':22B	2026-09-20 19:32:52.892621+00		1	2026-09-20 19:32:52.892621+00	\N
45	3	4	15b2a7743ac3b59c514aca18fe3f3823b3167603214e188903e251c6d21abda1	2026-09-08 09:40:00+00	bob pushed to <a href="https://gitea.zoo/bob/zoo-api-client/src/branch/esbuild">esbuild</a> at <a href="https://gitea.zoo/bob/zoo-api-client">bob/zoo-api-client</a>	https://gitea.zoo/bob/zoo-api-client/commit/1e05f4da332efafab686393625c49fca99f0631e	bob	<a href="https://gitea.zoo/bob/zoo-api-client/commit/1e05f4da332efafab686393625c49fca99f0631e" rel="noopener noreferrer" target="_blank" referrerpolicy="no-referrer">1e05f4da332efafab686393625c49fca99f0631e</a>\nBuild with esbuild	unread	f		'1e05':7B 'bob':1A 'bob/zoo-api-client':6A 'build':9B 'esbuild':4A,11B 'f4da332efafab686393625c49fca99f0631e':8B 'push':2A	2026-09-20 19:32:52.893372+00		1	2026-09-20 19:32:52.893372+00	\N
46	3	4	1133a821a24f834b098f2f74f2c6f0c22f7c8a21f2ce7d250c4873e7ad39996b	2026-09-08 09:40:00+00	bob created branch <a href="https://gitea.zoo/bob/zoo-api-client/src/branch/esbuild">esbuild</a> in <a href="https://gitea.zoo/bob/zoo-api-client">bob/zoo-api-client</a>	https://gitea.zoo/bob/zoo-api-client/src/branch/esbuild	bob		unread	f		'bob':1A 'bob/zoo-api-client':6A 'branch':3A 'creat':2A 'esbuild':4A	2026-09-20 19:32:52.894038+00		0	2026-09-20 19:32:52.894038+00	\N
47	3	4	f1c5796f3453894a992c2a7254a542eae71380203a51f7fc7022e3e88a53183e	2026-09-08 10:00:00+00	bob created pull request <a href="https://gitea.zoo/bob/zoo-api-client/pulls/3">bob/zoo-api-client#3</a>	https://gitea.zoo/bob/zoo-api-client/pulls/3	bob	<p>Cuts the build from about 3 seconds to under 100 ms.</p>\n	unread	f		'100':16B '3':6A,12B 'bob':1A 'bob/zoo-api-client':5A 'build':9B 'creat':2A 'cut':7B 'ms':17B 'pull':3A 'request':4A 'second':13B	2026-09-20 19:32:52.894604+00		1	2026-09-20 19:32:52.894604+00	\N
48	3	4	a37fe0bd62cbef11499a1d4510fcdc145cf40f88a364b838c18f3f3a197b9050	2026-09-08 11:30:00+00	alex.chen commented on pull request <a href="https://gitea.zoo/bob/zoo-api-client/pulls/3">bob/zoo-api-client#3</a>	https://gitea.zoo/bob/zoo-api-client/pulls/3#issuecomment-41	alex.chen	Build with esbuild instead of tsc\n\n<p>esbuild doesn&#39;t emit <code>.d.ts</code> files, and <code>types</code> points at <code>dist/index.d.ts</code>. We&#39;d still need <code>tsc --emitDeclarationOnly</code>, so the build wouldn&#39;t get simpler.</p>\n	unread	f		'3':7A 'alex.chen':1A 'bob/zoo-api-client':6A 'build':8B,33B 'comment':2A 'd':26B 'd.ts':18B 'dist/index.d.ts':24B 'doesn':15B 'emit':17B 'emitdeclarationon':30B 'esbuild':10B,14B 'file':19B 'get':36B 'instead':11B 'need':28B 'point':22B 'pull':4A 'request':5A 'simpler':37B 'still':27B 'tsc':13B,29B 'type':21B 'wouldn':34B	2026-09-20 19:32:52.895031+00		1	2026-09-20 19:32:52.895031+00	\N
49	3	4	6176a04a84c37b56690509e336ca70776971750b5359aed46c1218b6c89e91fc	2026-09-08 12:02:00+00	bob commented on pull request <a href="https://gitea.zoo/bob/zoo-api-client/pulls/3">bob/zoo-api-client#3</a>	https://gitea.zoo/bob/zoo-api-client/pulls/3#issuecomment-42	bob	Build with esbuild instead of tsc\n\n<p>Fair point, and the build is fast enough. Closing.</p>\n	unread	f		'3':7A 'bob':1A 'bob/zoo-api-client':6A 'build':8B,18B 'close':22B 'comment':2A 'enough':21B 'esbuild':10B 'fair':14B 'fast':20B 'instead':11B 'point':15B 'pull':4A 'request':5A 'tsc':13B	2026-09-20 19:32:52.895481+00		1	2026-09-20 19:32:52.895481+00	\N
50	3	4	de21bfe82dc1715f52423b0452d70db06150d1237e3a0c0dbc3ec46c52f8e14c	2026-09-08 12:03:00+00	bob closed pull request <a href="https://gitea.zoo/bob/zoo-api-client/pulls/3">bob/zoo-api-client#3</a>	https://gitea.zoo/bob/zoo-api-client/pulls/3#issuecomment-43	bob	Build with esbuild instead of tsc	unread	f		'3':6A 'bob':1A 'bob/zoo-api-client':5A 'build':7B 'close':2A 'esbuild':9B 'instead':10B 'pull':3A 'request':4A 'tsc':12B	2026-09-20 19:32:52.895928+00		1	2026-09-20 19:32:52.895928+00	\N
51	3	5	c0f6ecb3e260089101db7f5e631a711b29b3250ba684ae1a027530644536d9ea	2025-10-09 23:27:54+00	admin created repository <a href="https://gitea.zoo/zoo-labs/commander-mirror">zoo-labs/commander-mirror</a>	https://gitea.zoo/zoo-labs/commander-mirror	admin		unread	f		'/commander-mirror':7A 'admin':1A 'creat':2A 'lab':6A 'repositori':3A 'zoo':5A 'zoo-lab':4A	2026-09-20 19:32:52.965152+00		0	2026-09-20 19:32:52.965152+00	\N
52	3	5	063c7ad33cb9e95b2ae4f1f730d80f58338d2b4b4be4dfffcc809977772fde12	2025-10-09 23:27:55+00	admin created repository <a href="https://gitea.zoo/zoo-labs/zoo-utilities">zoo-labs/zoo-utilities</a>	https://gitea.zoo/zoo-labs/zoo-utilities	admin		unread	f		'/zoo-utilities':7A 'admin':1A 'creat':2A 'lab':6A 'repositori':3A 'zoo':5A 'zoo-lab':4A	2026-09-20 19:32:52.965636+00		0	2026-09-20 19:32:52.965636+00	\N
53	3	5	e8105b1c4e69dc84f076ccbba20d5723ee5954d36b3f0d42adb9749f23fb7b35	2026-09-01 09:12:00+00	grace opened issue <a href="https://gitea.zoo/zoo-labs/zoo-utilities/issues/1">zoo-labs/zoo-utilities#1</a>	https://gitea.zoo/zoo-labs/zoo-utilities/issues/1	grace	<p><code>lib/auth.js</code> builds tokens from <code>Math.random().toString(36)</code>. The output is predictable and only about 11 characters long, so it shouldn&#39;t be used for session or password reset tokens.</p>\n<p>We should use <code>crypto.randomBytes</code> instead.</p>\n	unread	f		'/zoo-utilities':7A '1':8A '11':23B '36':15B 'build':10B 'charact':24B 'crypto.randombytes':41B 'grace':1A 'instead':42B 'issu':3A 'lab':6A 'lib/auth.js':9B 'long':25B 'math.random':13B 'open':2A 'output':17B 'password':35B 'predict':19B 'reset':36B 'session':33B 'shouldn':28B 'token':11B,37B 'tostr':14B 'use':31B,40B 'zoo':5A 'zoo-lab':4A	2026-09-20 19:32:52.966021+00		1	2026-09-20 19:32:52.966021+00	\N
54	3	5	037847030e3e04eb84bc34e7e35450569a49967f491c8901adc07c721c6b4703	2026-09-01 10:03:00+00	alice commented on issue <a href="https://gitea.zoo/zoo-labs/zoo-utilities/issues/1">zoo-labs/zoo-utilities#1</a>	https://gitea.zoo/zoo-labs/zoo-utilities/issues/1#issuecomment-12	alice	generateToken uses Math.random, which is not secure\n\n<p>Agreed. I&#39;ll open a PR that switches to <code>crypto.randomBytes(32)</code> and hex-encodes the result.</p>\n	unread	f		'/zoo-utilities':8A '1':9A '32':27B 'agre':17B 'alic':1A 'comment':2A 'crypto.randombytes':26B 'encod':31B 'generatetoken':10B 'hex':30B 'hex-encod':29B 'issu':4A 'lab':7A 'll':19B 'math.random':12B 'open':20B 'pr':22B 'result':33B 'secur':16B 'switch':24B 'use':11B 'zoo':6A 'zoo-lab':5A	2026-09-20 19:32:52.966483+00		1	2026-09-20 19:32:52.966483+00	\N
55	3	5	6c7b448198c090faf1ec2ab4a2b0a439a135b52c9a93f28d9bc5bb05e1060378	2026-09-02 08:30:00+00	blake.sullivan commented on issue <a href="https://gitea.zoo/zoo-labs/zoo-utilities/issues/1">zoo-labs/zoo-utilities#1</a>	https://gitea.zoo/zoo-labs/zoo-utilities/issues/1#issuecomment-13	blake.sullivan	generateToken uses Math.random, which is not secure\n\n<p>Thanks both. This one blocks v1.3.0.</p>\n	unread	f		'/zoo-utilities':8A '1':9A 'blake.sullivan':1A 'block':21B 'comment':2A 'generatetoken':10B 'issu':4A 'lab':7A 'math.random':12B 'one':20B 'secur':16B 'thank':17B 'use':11B 'v1.3.0':22B 'zoo':6A 'zoo-lab':5A	2026-09-20 19:32:52.966936+00		1	2026-09-20 19:32:52.966936+00	\N
56	3	5	448fd60aefabd49921396820f4941235e14cbbac2cb5ac4ecaea06a3a10638ae	2026-09-03 14:20:00+00	alex.chen opened issue <a href="https://gitea.zoo/zoo-labs/zoo-utilities/issues/2">zoo-labs/zoo-utilities#2</a>	https://gitea.zoo/zoo-labs/zoo-utilities/issues/2	alex.chen	<p><code>index.js</code> requires <code>./lib/db</code> and <code>./lib/validators</code>, but neither file is in the repo, so importing the package throws:</p>\n<pre><code>Error: Cannot find module &#39;./lib/db&#39;\n</code></pre><p>Either add the modules or drop them from <code>index.js</code>.</p>\n	unread	f		'./lib/db':11B,30B './lib/validators':13B '/zoo-utilities':7A '2':8A 'add':32B 'alex.chen':1A 'cannot':27B 'drop':36B 'either':31B 'error':26B 'file':16B 'find':28B 'import':22B 'index.js':9B,39B 'issu':3A 'lab':6A 'modul':29B,34B 'neither':15B 'open':2A 'packag':24B 'repo':20B 'requir':10B 'throw':25B 'zoo':5A 'zoo-lab':4A	2026-09-20 19:32:52.967338+00		1	2026-09-20 19:32:52.967338+00	\N
57	3	5	4d9ee9a67a361f765635372de102ac592ad8822974138c2f20bac4944d885bb9	2026-09-03 15:02:00+00	bob commented on issue <a href="https://gitea.zoo/zoo-labs/zoo-utilities/issues/2">zoo-labs/zoo-utilities#2</a>	https://gitea.zoo/zoo-labs/zoo-utilities/issues/2#issuecomment-22	bob	require(&#39;@zoo-labs/utilities&#39;) fails: lib/db.js is missing\n\n<p>Confirmed on a clean install. I&#39;d rather add minimal modules than change the exports.</p>\n	unread	f		'/utilities':14B '/zoo-utilities':8A '2':9A 'add':27B 'bob':1A 'chang':31B 'clean':22B 'comment':2A 'confirm':19B 'd':25B 'export':33B 'fail':15B 'instal':23B 'issu':4A 'lab':7A,13B 'lib/db.js':16B 'minim':28B 'miss':18B 'modul':29B 'rather':26B 'requir':10B 'zoo':6A,12B 'zoo-lab':5A,11B	2026-09-20 19:32:52.967742+00		1	2026-09-20 19:32:52.967742+00	\N
58	3	5	32e54d95aec897d2dadd278ecf982f28b80e8e8b0e3948173d19c0cb271cb80c	2026-09-04 16:40:00+00	eve opened issue <a href="https://gitea.zoo/zoo-labs/zoo-utilities/issues/3">zoo-labs/zoo-utilities#3</a>	https://gitea.zoo/zoo-labs/zoo-utilities/issues/3	eve	<p><code>validateToken(&#39;x&#39;)</code> returns <code>true</code>. I expected it to reject strings that <code>generateToken</code> could never produce.</p>\n	unread	f		'/zoo-utilities':7A '3':8A 'could':21B 'eve':1A 'expect':14B 'generatetoken':20B 'issu':3A 'lab':6A 'never':22B 'open':2A 'produc':23B 'reject':17B 'return':11B 'string':18B 'true':12B 'validatetoken':9B 'x':10B 'zoo':5A 'zoo-lab':4A	2026-09-20 19:32:52.968302+00		1	2026-09-20 19:32:52.968302+00	\N
59	3	5	363412cc01a79f778e0ac848d1191fcfafc31c99d9f82bc5895d8bc842e2c4d4	2026-09-05 13:40:00+00	alice created branch <a href="https://gitea.zoo/zoo-labs/zoo-utilities/src/branch/alice/secure-tokens">alice/secure-tokens</a> in <a href="https://gitea.zoo/zoo-labs/zoo-utilities">zoo-labs/zoo-utilities</a>	https://gitea.zoo/zoo-labs/zoo-utilities/src/branch/alice/secure-tokens	alice		unread	f		'/zoo-utilities':9A 'alic':1A 'alice/secure-tokens':4A 'branch':3A 'creat':2A 'lab':8A 'zoo':7A 'zoo-lab':6A	2026-09-20 19:32:52.968676+00		0	2026-09-20 19:32:52.968676+00	\N
60	3	5	50fe38abed5186bf304bae38da410d8be3d1d29e41c3ae4f4fe14e172830e48d	2026-09-05 13:40:00+00	alice pushed to <a href="https://gitea.zoo/zoo-labs/zoo-utilities/src/branch/alice/secure-tokens">alice/secure-tokens</a> at <a href="https://gitea.zoo/zoo-labs/zoo-utilities">zoo-labs/zoo-utilities</a>	https://gitea.zoo/zoo-labs/zoo-utilities/commit/8ab025ddf7993b79a8e8d570f557601ec1f04608	alice	<a href="https://gitea.zoo/zoo-labs/zoo-utilities/commit/8ab025ddf7993b79a8e8d570f557601ec1f04608" rel="noopener noreferrer" target="_blank" referrerpolicy="no-referrer">8ab025ddf7993b79a8e8d570f557601ec1f04608</a>\nGenerate auth tokens with crypto.randomBytes	unread	f		'/zoo-utilities':9A '8ab025ddf7993b79a8e8d570f557601ec1f04608':10B 'alic':1A 'alice/secure-tokens':4A 'auth':12B 'crypto.randombytes':15B 'generat':11B 'lab':8A 'push':2A 'token':13B 'zoo':7A 'zoo-lab':6A	2026-09-20 19:32:52.969052+00		1	2026-09-20 19:32:52.969052+00	\N
61	3	5	d663f3126e5c9c670248df014b1ce548b16f81c433811e1d2e234d30acc13a3f	2026-09-05 13:52:00+00	alice created pull request <a href="https://gitea.zoo/zoo-labs/zoo-utilities/pulls/4">zoo-labs/zoo-utilities#4</a>	https://gitea.zoo/zoo-labs/zoo-utilities/pulls/4	alice	<p>Fixes <a href="https://gitea.zoo/zoo-labs/zoo-utilities/issues/1" rel="noopener noreferrer" target="_blank" referrerpolicy="no-referrer">#1</a>.</p>\n<ul>\n<li><code>generateToken</code> returns 32 random bytes, hex-encoded</li>\n<li><code>validateToken</code> accepts only 64 hex characters</li>\n</ul>\n	unread	f		'/zoo-utilities':8A '1':11B '32':14B '4':9A '64':23B 'accept':21B 'alic':1A 'byte':16B 'charact':25B 'creat':2A 'encod':19B 'fix':10B 'generatetoken':12B 'hex':18B,24B 'hex-encod':17B 'lab':7A 'pull':3A 'random':15B 'request':4A 'return':13B 'validatetoken':20B 'zoo':6A 'zoo-lab':5A	2026-09-20 19:32:52.96944+00		1	2026-09-20 19:32:52.96944+00	\N
62	3	5	cd95ec04849d734e020ed69ca1ee52d9337502050728aa5997bda76bcfd8f3f8	2026-09-05 14:05:00+00	alice commented on issue <a href="https://gitea.zoo/zoo-labs/zoo-utilities/issues/3">zoo-labs/zoo-utilities#3</a>	https://gitea.zoo/zoo-labs/zoo-utilities/issues/3#issuecomment-31	alice	validateToken accepts any non-empty string\n\n<p>Same root cause as <a href="https://gitea.zoo/zoo-labs/zoo-utilities/issues/1" rel="noopener noreferrer" target="_blank" referrerpolicy="no-referrer">#1</a>: tokens have no fixed format yet. <a href="https://gitea.zoo/zoo-labs/zoo-utilities/issues/4" rel="noopener noreferrer" target="_blank" referrerpolicy="no-referrer">#4</a> makes them 64 hex characters and checks for exactly that, so I&#39;m closing this as a duplicate.</p>\n	unread	f		'/zoo-utilities':8A '1':21B '3':9A '4':28B '64':31B 'accept':11B 'alic':1A 'caus':19B 'charact':33B 'check':35B 'close':42B 'comment':2A 'duplic':46B 'empti':15B 'exact':37B 'fix':25B 'format':26B 'hex':32B 'issu':4A 'lab':7A 'm':41B 'make':29B 'non':14B 'non-empti':13B 'root':18B 'string':16B 'token':22B 'validatetoken':10B 'yet':27B 'zoo':6A 'zoo-lab':5A	2026-09-20 19:32:52.969815+00		1	2026-09-20 19:32:52.969815+00	\N
63	3	5	acd83fe5572ed9a6025f95b08fe00eeef255f33f484e7cbe22196e5e8955bad8	2026-09-05 14:06:00+00	alice closed issue <a href="https://gitea.zoo/zoo-labs/zoo-utilities/issues/3">zoo-labs/zoo-utilities#3</a>	https://gitea.zoo/zoo-labs/zoo-utilities/issues/3#issuecomment-34	alice	validateToken accepts any non-empty string	unread	f		'/zoo-utilities':7A '3':8A 'accept':10B 'alic':1A 'close':2A 'empti':14B 'issu':3A 'lab':6A 'non':13B 'non-empti':12B 'string':15B 'validatetoken':9B 'zoo':5A 'zoo-lab':4A	2026-09-20 19:32:52.970216+00		1	2026-09-20 19:32:52.970216+00	\N
64	3	5	e5a9f96d73024e7b2ad31d73298836220f1b7019fe5d62c28051e58ed71a8460	2026-09-07 09:05:00+00	grace commented on pull request <a href="https://gitea.zoo/zoo-labs/zoo-utilities/pulls/4">zoo-labs/zoo-utilities#4</a>	https://gitea.zoo/zoo-labs/zoo-utilities/pulls/4#issuecomment-38	grace	Generate auth tokens with crypto.randomBytes\n\n<p>Looks good to me, one question inline.</p>\n	unread	f		'/zoo-utilities':9A '4':10A 'auth':12B 'comment':2A 'crypto.randombytes':15B 'generat':11B 'good':17B 'grace':1A 'inlin':22B 'lab':8A 'look':16B 'one':20B 'pull':4A 'question':21B 'request':5A 'token':13B 'zoo':7A 'zoo-lab':6A	2026-09-20 19:32:52.971667+00		1	2026-09-20 19:32:52.971667+00	\N
65	3	5	c68a1068342e7577b6560dbc14ee782cbb439040708cb3ae606f5080861cbd45	2026-09-07 09:05:00+00	grace commented on pull request <a href="https://gitea.zoo/zoo-labs/zoo-utilities/pulls/4">zoo-labs/zoo-utilities#4</a>	https://gitea.zoo/zoo-labs/zoo-utilities/pulls/4#issuecomment-37	grace	Generate auth tokens with crypto.randomBytes\n\n<p>Could the byte count be an argument? The invite links in zoo-api-client want shorter tokens.</p>\n	unread	f		'/zoo-utilities':9A '4':10A 'api':29B 'argument':22B 'auth':12B 'byte':18B 'client':30B 'comment':2A 'could':16B 'count':19B 'crypto.randombytes':15B 'generat':11B 'grace':1A 'invit':24B 'lab':8A 'link':25B 'pull':4A 'request':5A 'shorter':32B 'token':13B,33B 'want':31B 'zoo':7A,28B 'zoo-api-cli':27B 'zoo-lab':6A	2026-09-20 19:32:52.972051+00		1	2026-09-20 19:32:52.972051+00	\N
66	3	5	e29d5f60379795658dacd98f5395de32c1b0f182e64e018bad061234b903f512	2026-09-07 11:30:00+00	alice commented on pull request <a href="https://gitea.zoo/zoo-labs/zoo-utilities/pulls/4">zoo-labs/zoo-utilities#4</a>	https://gitea.zoo/zoo-labs/zoo-utilities/pulls/4#issuecomment-39	alice	Generate auth tokens with crypto.randomBytes\n\n<p>Good idea. I&#39;ll add an optional <code>bytes</code> argument that defaults to 32.</p>\n	unread	f		'/zoo-utilities':9A '32':28B '4':10A 'add':20B 'alic':1A 'argument':24B 'auth':12B 'byte':23B 'comment':2A 'crypto.randombytes':15B 'default':26B 'generat':11B 'good':16B 'idea':17B 'lab':8A 'll':19B 'option':22B 'pull':4A 'request':5A 'token':13B 'zoo':7A 'zoo-lab':6A	2026-09-20 19:32:52.972466+00		1	2026-09-20 19:32:52.972466+00	\N
67	4	6	b97946768944443a945cf7ecd18c05ce46d47d8dd4e1435206381eb015659511	2025-10-09 23:27:53+00	admin created repository <a href="https://gitea.zoo/community/awesome-zoo">community/awesome-zoo</a>	https://gitea.zoo/community/awesome-zoo	admin		unread	f		'admin':1A 'community/awesome-zoo':4A 'creat':2A 'repositori':3A	2026-09-20 19:32:53.200199+00		0	2026-09-20 19:32:53.200199+00	\N
68	4	6	51fd9d614288dac4cf29eee5215ea65073edcb1ca95efae3530ae4c5c2412a19	2026-08-31 18:45:00+00	mallory opened issue <a href="https://gitea.zoo/community/awesome-zoo/issues/1">community/awesome-zoo#1</a>	https://gitea.zoo/community/awesome-zoo/issues/1	mallory	<p><a href="https://gitea.zoo/charlie/zoo-docker-templates" rel="noopener noreferrer" target="_blank" referrerpolicy="no-referrer">https://gitea.zoo/charlie/zoo-docker-templates</a> has ready-to-use Docker setups for zoo services and isn&#39;t on the list yet.</p>\n	unread	f		'/charlie/zoo-docker-templates':8B '1':5A 'community/awesome-zoo':4A 'docker':14B 'gitea.zoo':7B 'gitea.zoo/charlie/zoo-docker-templates':6B 'isn':20B 'issu':3A 'list':24B 'mallori':1A 'open':2A 'readi':11B 'ready-to-us':10B 'servic':18B 'setup':15B 'use':13B 'yet':25B 'zoo':17B	2026-09-20 19:32:53.200845+00		1	2026-09-20 19:32:53.200845+00	\N
69	4	6	f23685e09cbb479817d6016de2e09e15b3a727584f61ec6ca35ecf0e46a428b8	2026-09-01 08:20:00+00	charlie commented on issue <a href="https://gitea.zoo/community/awesome-zoo/issues/1">community/awesome-zoo#1</a>	https://gitea.zoo/community/awesome-zoo/issues/1#issuecomment-7	charlie	Add Zoo Docker Templates to Community Projects\n\n<p>Good idea, I&#39;ll add it. PRs welcome too!</p>\n	unread	f		'1':6A 'add':7B,18B 'charli':1A 'comment':2A 'communiti':12B 'community/awesome-zoo':5A 'docker':9B 'good':14B 'idea':15B 'issu':4A 'll':17B 'project':13B 'prs':20B 'templat':10B 'welcom':21B 'zoo':8B	2026-09-20 19:32:53.201347+00		1	2026-09-20 19:32:53.201347+00	\N
70	4	6	bbf35fc900e663db579e79d71a86528058cf80e2bcf5d80bbfaf3ba69e7b9fcc	2026-09-06 12:10:00+00	diana opened issue <a href="https://gitea.zoo/community/awesome-zoo/issues/2">community/awesome-zoo#2</a>	https://gitea.zoo/community/awesome-zoo/issues/2	diana	<p>The table of contents links to Tools and Tutorials, but the README has no such sections, so both links go nowhere.</p>\n	unread	f		'2':5A 'community/awesome-zoo':4A 'content':9B 'diana':1A 'go':25B 'issu':3A 'link':10B,24B 'nowher':26B 'open':2A 'readm':17B 'section':21B 'tabl':7B 'tool':12B 'tutori':14B	2026-09-20 19:32:53.201872+00		1	2026-09-20 19:32:53.201872+00	\N
71	7	7	3b618633831486b3fbe525284f3c92ae73526b13c06096f57eafebf9080b8d30	2025-10-09 23:05:03+00	Initial commit	https://gitea.zoo/zoo-labs/zoo-utilities/commit/8169955edfc4fd20a20736278928e08cd2a7dcc5	Zoo Labs	Initial commit\n	unread	f		'commit':2A,4B 'initi':1A,3B	2026-09-20 19:32:53.428499+00		1	2026-09-20 19:32:53.428499+00	\N
72	7	8	75eb2d3ead45e6c63d7fa44f9817c8f13d96a6d2b463bf1eb4859758089a5a11	2025-10-09 23:05:03+00	Initial commit	https://gitea.zoo/alice/hello-zoo/commit/d311d7fe94f9a8b00029c871254f4ccd5c4d6813	Alice Johnson	Initial commit\n	unread	f		'commit':2A,4B 'initi':1A,3B	2026-09-20 19:32:53.549585+00		1	2026-09-20 19:32:53.549585+00	\N
\.


--
-- Data for Name: feed_icons; Type: TABLE DATA; Schema: public; Owner: miniflux_user
--

COPY public.feed_icons (feed_id, icon_id) FROM stdin;
1	1
2	1
3	1
4	1
5	1
6	1
7	1
8	1
\.


--
-- Data for Name: feeds; Type: TABLE DATA; Schema: public; Owner: miniflux_user
--

COPY public.feeds (id, user_id, category_id, title, feed_url, site_url, checked_at, etag_header, last_modified_header, parsing_error_msg, parsing_error_count, scraper_rules, rewrite_rules, crawler, username, password, user_agent, disabled, next_check_at, ignore_http_cache, fetch_via_proxy, blocklist_rules, keeplist_rules, allow_self_signed_certificates, cookie, hide_globally, url_rewrite_rules, no_media_player, apprise_service_urls, disable_http2, description, ntfy_enabled, ntfy_priority, webhook_url, pushover_enabled, pushover_priority, ntfy_topic, proxy_url) FROM stdin;
1	2	15	Feed of "zoo-labs/zoo-utilities"	https://gitea.zoo/zoo-labs/zoo-utilities.rss	https://gitea.zoo/zoo-labs/zoo-utilities	2026-09-20 19:32:52.331212+00				0			f				f	2026-09-20 19:32:52.331212+00	f	f			f		f		f		f	Common utilities for Zoo applications	f	3		f	0		
2	2	15	Feed of "Zoo Labs"	https://gitea.zoo/zoo-labs.rss	https://gitea.zoo/zoo-labs	2026-09-20 19:32:52.411339+00				0			f				f	2026-09-20 19:32:52.411339+00	f	f			f		f		f		f	<p dir="auto">Official Zoo development organization</p>	f	3		f	0		
3	2	16	Feed of "alice/hello-zoo"	https://gitea.zoo/alice/hello-zoo.rss	https://gitea.zoo/alice/hello-zoo	2026-09-20 19:32:52.653709+00				0			f				f	2026-09-20 19:32:52.653709+00	f	f			f		f		f		f	A simple Hello World application for the Zoo	f	3		f	0		
4	3	17	Feed of "bob/zoo-api-client"	https://gitea.zoo/bob/zoo-api-client.rss	https://gitea.zoo/bob/zoo-api-client	2026-09-20 19:32:52.889733+00				0			f				f	2026-09-20 19:32:52.889733+00	f	f			f		f		f		f	API client library for Zoo services	f	3		f	0		
5	3	17	Feed of "Zoo Labs"	https://gitea.zoo/zoo-labs.rss	https://gitea.zoo/zoo-labs	2026-09-20 19:32:52.964623+00				0			f				f	2026-09-20 19:32:52.964623+00	f	f			f		f		f		f	<p dir="auto">Official Zoo development organization</p>	f	3		f	0		
6	4	18	Feed of "community/awesome-zoo"	https://gitea.zoo/community/awesome-zoo.rss	https://gitea.zoo/community/awesome-zoo	2026-09-20 19:32:53.199874+00				0			f				f	2026-09-20 19:32:53.199874+00	f	f			f		f		f		f	A curated list of awesome Zoo resources	f	3		f	0		
7	7	19	zoo-utilities commits	https://gitea.zoo/zoo-labs/zoo-utilities/rss/branch/master	https://gitea.zoo/zoo-labs/zoo-utilities/src/branch/master	2026-09-20 19:32:53.428224+00				0			f				f	2026-09-20 19:32:53.428224+00	f	f			f		f		f		f	Common utilities for Zoo applications	f	3		f	0		
8	7	19	hello-zoo commits	https://gitea.zoo/alice/hello-zoo/rss/branch/master	https://gitea.zoo/alice/hello-zoo/src/branch/master	2026-09-20 19:32:53.549278+00				0			f				f	2026-09-20 19:32:53.549278+00	f	f			f		f		f		f	A simple Hello World application for the Zoo	f	3		f	0		
\.


--
-- Data for Name: icons; Type: TABLE DATA; Schema: public; Owner: miniflux_user
--

COPY public.icons (id, hash, mime_type, content, external_id) FROM stdin;
1	ab8b24d9c8863b8961221e3a64e349d7bc8d7a1f2d10ea5b96049ad1740efdba	image/svg+xml	\\x3c73766720786d6c6e733d22687474703a2f2f7777772e77332e6f72672f323030302f7376672220786d6c3a73706163653d227072657365727665222076696577426f783d223020302036343020363430222077696474683d22333222206865696768743d223332223e3c7061746820643d226d3339352e39203438342e322d3132362e392d3631632d31322e352d362d31372e392d32312e322d31312e382d33332e386c36312d3132362e3963362d31322e352032312e322d31372e392033332e382d31312e382031372e3220382e332032372e312031332032372e312031336c2d2e312d3130392e322031362e372d2e312e31203131372e317335372e342032342e322038332e312034302e3163332e3720322e332031302e3220362e382031322e392031342e3420322e3120362e3120322031332e312d312031392e336c2d3631203132362e39632d362e322031322e372d32312e342031382e312d33332e3920313222207374796c653d2266696c6c3a23666666222f3e3c7061746820643d224d3632322e37203134392e38632d342e312d342e312d392e362d342d392e362d34732d3131372e3220362e362d3137372e392038632d31332e332e332d32362e352e362d33392e362e37763131372e32632d352e352d322e362d31312e312d352e332d31362e362d372e3920302d33362e342d2e312d3130392e322d2e312d3130392e322d3239202e342d38392e322d322e322d38392e322d322e32732d3134312e342d372e312d3135362e382d382e35632d392e382d2e362d32322e352d322e312d333920312e352d382e3720312e382d33332e3520372e342d35332e382032362e39432d342e39203231322e3420362e36203237362e322038203238352e3863312e372031312e3720362e392034342e322033312e372037322e352034352e382035362e31203134342e342035342e38203134342e342035342e387331322e312032382e392033302e362035352e356332352033332e312035302e372035382e392037352e372036322036332030203138382e392d2e31203138382e392d2e31733132202e312032382e332d31302e336331342d382e352032362e352d32332e342032362e352d32332e34533534372034383320353635203435312e3563352e352d392e372031302e312d31392e312031342e312d3238203020302035352e322d3131372e312035352e322d3233312e312d312e312d33342e352d392e362d34302e362d31312e362d34322e364d3132352e36203335332e39632d32352e392d382e352d33362e392d31382e372d33362e392d31382e375336392e36203332312e38203630203239352e34632d31362e352d34342e322d312e342d37312e322d312e342d37312e3273382e342d32322e352033382e352d33306331332e382d332e372033312d332e312033312d332e3173372e312035392e342031352e372039342e3263372e322032392e322032342e382037372e372032342e382037372e37732d32362e312d332e312d34332d392e316d3330302e33203130372e36732d362e312031342e352d31392e362031352e34632d352e382e342d31302e332d312e322d31302e332d312e32732d2e332d2e312d352e332d322e316c2d3131322e392d3535732d31302e392d352e372d31322e382d31352e36632d322e322d382e3120322e372d31382e3120322e372d31382e314c3332322032373373342e382d392e372031322e322d3133632e362d2e3320322e332d3120342e352d312e3520382e312d322e3120313820322e3820313820322e384c3436372e34203331357331322e3620352e372031352e332031362e3263312e3920372e342d2e352031342d312e382031372e322d362e332031352e342d3535203131332e312d3535203131332e3122207374796c653d2266696c6c3a23363039393236222f3e3c7061746820643d224d3332362e38203338302e31632d382e322e312d31352e3420352e382d31372e332031332e3873322031362e3320392e3120323063372e3720342031372e3520312e382032322e372d352e3420352e312d372e3120342e332d31362e392d312e382d32332e316c32342d34392e3163312e352e3120332e372e3220362e322d2e3520342e312d2e3920372e312d332e3620372e312d332e3620342e3220312e3820382e3620332e382031332e3220362e3120342e3820322e3420392e3320342e392031332e3420372e332e392e3520312e3820312e3120322e3820312e3920312e3620312e3320332e3420332e3120342e3720352e3520312e3920352e352d312e392031342e392d312e392031342e392d322e3320372e362d31382e342034302e362d31382e342034302e362d382e312d2e322d31352e3320352d31372e372031322e352d322e3620382e3120312e312031372e3320382e392032312e337331372e3420312e372032322e352d352e3363352d362e3820342e362d31362e332d312e312d32322e3620312e392d332e3720332e372d372e3420352e362d31312e3320352d31302e342031332e352d33302e342031332e352d33302e342e392d312e3720352e372d31302e3320322e372d32312e332d322e352d31312e342d31322e362d31362e372d31322e362d31362e372d31322e322d372e392d32392e322d31352e322d32392e322d31352e3273302d342e312d312e312d372e31632d312e312d332e312d322e382d352e312d332e392d362e3320342e372d392e3720392e342d31392e332031342e312d32392d342e312d322d382e312d342d31322e322d362e312d342e3820392e382d392e372031392e372d31342e352032392e352d362e372d2e312d31322e3920332e352d31362e3120392e342d332e3420362e332d322e372031342e3120312e392031392e387a22207374796c653d2266696c6c3a23363039393236222f3e3c2f7376673e	541e59bbe9c9fbe937142e4f97f89d69b5d22798
\.


--
-- Data for Name: integrations; Type: TABLE DATA; Schema: public; Owner: miniflux_user
--

COPY public.integrations (user_id, pinboard_enabled, pinboard_token, pinboard_tags, pinboard_mark_as_unread, instapaper_enabled, instapaper_username, instapaper_password, fever_enabled, fever_username, fever_token, wallabag_enabled, wallabag_url, wallabag_client_id, wallabag_client_secret, wallabag_username, wallabag_password, nunux_keeper_enabled, nunux_keeper_url, nunux_keeper_api_key, pocket_enabled, pocket_access_token, pocket_consumer_key, telegram_bot_enabled, telegram_bot_token, telegram_bot_chat_id, googlereader_enabled, googlereader_username, googlereader_password, espial_enabled, espial_url, espial_api_key, espial_tags, linkding_enabled, linkding_url, linkding_api_key, wallabag_only_url, matrix_bot_enabled, matrix_bot_user, matrix_bot_password, matrix_bot_url, matrix_bot_chat_id, linkding_tags, linkding_mark_as_unread, notion_enabled, notion_token, notion_page_id, readwise_enabled, readwise_api_key, apprise_enabled, apprise_url, apprise_services_url, shiori_enabled, shiori_url, shiori_username, shiori_password, shaarli_enabled, shaarli_url, shaarli_api_secret, webhook_enabled, webhook_url, webhook_secret, telegram_bot_topic_id, telegram_bot_disable_web_page_preview, telegram_bot_disable_notification, telegram_bot_disable_buttons, rssbridge_enabled, rssbridge_url, omnivore_enabled, omnivore_api_key, omnivore_url, linkace_enabled, linkace_url, linkace_api_key, linkace_tags, linkace_is_private, linkace_check_disabled, linkwarden_enabled, linkwarden_url, linkwarden_api_key, readeck_enabled, readeck_only_url, readeck_url, readeck_api_key, readeck_labels, raindrop_enabled, raindrop_token, raindrop_collection_id, raindrop_tags, betula_url, betula_token, betula_enabled, ntfy_enabled, ntfy_url, ntfy_topic, ntfy_api_token, ntfy_username, ntfy_password, ntfy_icon_url, cubox_enabled, cubox_api_link, discord_enabled, discord_webhook_link, ntfy_internal_links, slack_enabled, slack_webhook_link, pushover_enabled, pushover_user, pushover_token, pushover_device, pushover_prefix, rssbridge_token) FROM stdin;
1	f		miniflux	f	f			f			f						f			f			f			f			f			miniflux	f			f	f						f	f			f		f			f				f			f			\N	f	f	f	f		f			f				t	t	f			f	f				f						f	f							f		f		f	f		f					
2	f		miniflux	f	f			f			f						f			f			f			f			f			miniflux	f			f	f						f	f			f		f			f				f			f			\N	f	f	f	f		f			f				t	t	f			f	f				f						f	f							f		f		f	f		f					
3	f		miniflux	f	f			f			f						f			f			f			f			f			miniflux	f			f	f						f	f			f		f			f				f			f			\N	f	f	f	f		f			f				t	t	f			f	f				f						f	f							f		f		f	f		f					
4	f		miniflux	f	f			f			f						f			f			f			f			f			miniflux	f			f	f						f	f			f		f			f				f			f			\N	f	f	f	f		f			f				t	t	f			f	f				f						f	f							f		f		f	f		f					
5	f		miniflux	f	f			f			f						f			f			f			f			f			miniflux	f			f	f						f	f			f		f			f				f			f			\N	f	f	f	f		f			f				t	t	f			f	f				f						f	f							f		f		f	f		f					
6	f		miniflux	f	f			f			f						f			f			f			f			f			miniflux	f			f	f						f	f			f		f			f				f			f			\N	f	f	f	f		f			f				t	t	f			f	f				f						f	f							f		f		f	f		f					
7	f		miniflux	f	f			f			f						f			f			f			f			f			miniflux	f			f	f						f	f			f		f			f				f			f			\N	f	f	f	f		f			f				t	t	f			f	f				f						f	f							f		f		f	f		f					
8	f		miniflux	f	f			f			f						f			f			f			f			f			miniflux	f			f	f						f	f			f		f			f				f			f			\N	f	f	f	f		f			f				t	t	f			f	f				f						f	f							f		f		f	f		f					
9	f		miniflux	f	f			f			f						f			f			f			f			f			miniflux	f			f	f						f	f			f		f			f				f			f			\N	f	f	f	f		f			f				t	t	f			f	f				f						f	f							f		f		f	f		f					
10	f		miniflux	f	f			f			f						f			f			f			f			f			miniflux	f			f	f						f	f			f		f			f				f			f			\N	f	f	f	f		f			f				t	t	f			f	f				f						f	f							f		f		f	f		f					
11	f		miniflux	f	f			f			f						f			f			f			f			f			miniflux	f			f	f						f	f			f		f			f				f			f			\N	f	f	f	f		f			f				t	t	f			f	f				f						f	f							f		f		f	f		f					
12	f		miniflux	f	f			f			f						f			f			f			f			f			miniflux	f			f	f						f	f			f		f			f				f			f			\N	f	f	f	f		f			f				t	t	f			f	f				f						f	f							f		f		f	f		f					
13	f		miniflux	f	f			f			f						f			f			f			f			f			miniflux	f			f	f						f	f			f		f			f				f			f			\N	f	f	f	f		f			f				t	t	f			f	f				f						f	f							f		f		f	f		f					
14	f		miniflux	f	f			f			f						f			f			f			f			f			miniflux	f			f	f						f	f			f		f			f				f			f			\N	f	f	f	f		f			f				t	t	f			f	f				f						f	f							f		f		f	f		f					
\.


--
-- Data for Name: schema_version; Type: TABLE DATA; Schema: public; Owner: miniflux_user
--

COPY public.schema_version (version) FROM stdin;
110
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: miniflux_user
--

COPY public.users (id, username, password, is_admin, language, timezone, theme, last_login_at, entry_direction, keyboard_shortcuts, entries_per_page, show_reading_time, entry_swipe, stylesheet, google_id, openid_connect_id, display_mode, entry_order, default_reading_speed, cjk_reading_speed, default_home_page, categories_sorting_order, gesture_nav, mark_read_on_view, media_playback_rate, block_filter_entry_rules, keep_filter_entry_rules, mark_read_on_media_player_completion, custom_js, external_font_hosts, always_open_external_links) FROM stdin;
1	admin	$2a$10$0SKn0M.0CITOeRYkgPaY3ePGgxb338/fc3VMlAopvfhyn71woRuMq	t	en_US	UTC	light_serif	\N	asc	t	100	t	t			bf76d497-ef2e-51e2-a14d-3860791929c9	standalone	published_at	265	500	unread	unread_count	tap	t	1			f			f
2	alice	$2a$10$yDniENeGz1foJ3BZXv42femw/CGbSyuLSQIsYbrYOHtHWmpM0srku	f	en_US	UTC	light_serif	\N	asc	t	100	t	t			b608913a-c0d2-5141-808a-30eb1809bae2	standalone	published_at	265	500	unread	unread_count	tap	t	1			f			f
3	bob	$2a$10$pgpvYwri9f9GSp8O1JtU8ue8q9fqoiIByoyNOuDdEEqJ16h0jL58y	f	en_US	UTC	light_serif	\N	asc	t	100	t	t			21d2ca5f-25db-581a-9c58-7ed3b3aaef3e	standalone	published_at	265	500	unread	unread_count	tap	t	1			f			f
4	charlie	$2a$10$RMokmwTDnc/FTxb.7B7lMuaI1Pm6H7Q6s6yP7cZUeKqMeKEU8zGvq	f	en_US	UTC	light_serif	\N	asc	t	100	t	t			0fae1fa0-0dfd-511c-a865-69be6961afe7	standalone	published_at	265	500	unread	unread_count	tap	t	1			f			f
5	diana	$2a$10$.ddJxK/DmNdpXYqbf3JVwuqSbBdMd2GJfsDF53abZYwXARwNjfvne	f	en_US	UTC	light_serif	\N	asc	t	100	t	t			d6092304-e8bd-5344-8abd-28f18db5f9eb	standalone	published_at	265	500	unread	unread_count	tap	t	1			f			f
6	eve	$2a$10$I4jZetIJ8UjToKVc53PDXOMJcCMykIJZug3o99T.3JpkC7tETMdOi	f	en_US	UTC	light_serif	\N	asc	t	100	t	t			a906f37f-b3c5-5bd2-972e-5497fd6e7926	standalone	published_at	265	500	unread	unread_count	tap	t	1			f			f
7	frank	$2a$10$UYFGqIeLWVKGWVsAhaNPleO7SO43FB3uHwjvBA5eJWwDrj/wRVTcy	f	en_US	UTC	light_serif	\N	asc	t	100	t	t			007d86cc-b436-514b-ae85-57af1da0b729	standalone	published_at	265	500	unread	unread_count	tap	t	1			f			f
8	grace	$2a$10$4NOKf059gIWS8i0XcKMnMuveU6/Ob9ri5ovxn7lUjfMytlCEwbgqq	f	en_US	UTC	light_serif	\N	asc	t	100	t	t			b569288b-49f7-51a5-86d8-baa37149f20a	standalone	published_at	265	500	unread	unread_count	tap	t	1			f			f
9	demo	$2a$10$pwzzSUC8/3UFfmiXObw7ne6jPhdbW7r2c43Qz0iCK4KaycYrr3cSS	f	en_US	UTC	light_serif	\N	asc	t	100	t	t			b88e24e7-5ad4-55ca-9a67-face778e43a3	standalone	published_at	265	500	unread	unread_count	tap	t	1			f			f
10	user1	$2a$10$UoRWN5fir3VeVoGSiq8Dku92NSggekx297buL2GDbQaqIvf9yFUkW	f	en_US	UTC	light_serif	\N	asc	t	100	t	t			5200e09c-0a5d-50ea-b36f-6ff1367a5e52	standalone	published_at	265	500	unread	unread_count	tap	t	1			f			f
11	alex.chen	$2a$10$zMHYpk0wvTUoR.aCvwMxReP0UgBp15TdWpAjf64huyCCapFv0C/Ya	f	en_US	UTC	light_serif	\N	asc	t	100	t	t			4ef29f33-7958-5ff5-af29-73ff36834988	standalone	published_at	265	500	unread	unread_count	tap	t	1			f			f
12	blake.sullivan	$2a$10$3RW3n7SSpgDJEFUQs9/w2OyDAVZeHzuVXFPGbn1KD1uSXzlWntQI.	f	en_US	UTC	light_serif	\N	asc	t	100	t	t			94a79ee0-00af-5aea-ba5e-384191bc89c2	standalone	published_at	265	500	unread	unread_count	tap	t	1			f			f
13	mallory	$2a$10$WKa4b99ehJJVVPuU95OzsuXBFpCRZEOwvss6idmqqb4/0u9i1fFUG	f	en_US	UTC	light_serif	\N	asc	t	100	t	t			82ba4bb8-8b3c-5b06-a481-351f81a2a7ea	standalone	published_at	265	500	unread	unread_count	tap	t	1			f			f
14	analytics_user	$2a$10$dMK109i9BOSqQFF/M.CusOAt2mh7l5pK7mTsXHpWrdmYtwN2VmYr6	t	en_US	UTC	light_serif	\N	asc	t	100	t	t			3df993b7-ed35-5349-a475-67d23d52a52a	standalone	published_at	265	500	unread	unread_count	tap	t	1			f			f
\.


--
-- Data for Name: webauthn_credentials; Type: TABLE DATA; Schema: public; Owner: miniflux_user
--

COPY public.webauthn_credentials (handle, cred_id, user_id, public_key, attestation_type, aaguid, sign_count, clone_warning, name, added_on, last_seen_on) FROM stdin;
\.


--
-- Name: api_keys_id_seq; Type: SEQUENCE SET; Schema: public; Owner: miniflux_user
--

SELECT pg_catalog.setval('public.api_keys_id_seq', 1, false);


--
-- Name: categories_id_seq; Type: SEQUENCE SET; Schema: public; Owner: miniflux_user
--

SELECT pg_catalog.setval('public.categories_id_seq', 19, true);


--
-- Name: enclosures_id_seq; Type: SEQUENCE SET; Schema: public; Owner: miniflux_user
--

SELECT pg_catalog.setval('public.enclosures_id_seq', 1, false);


--
-- Name: entries_id_seq; Type: SEQUENCE SET; Schema: public; Owner: miniflux_user
--

SELECT pg_catalog.setval('public.entries_id_seq', 72, true);


--
-- Name: feeds_id_seq; Type: SEQUENCE SET; Schema: public; Owner: miniflux_user
--

SELECT pg_catalog.setval('public.feeds_id_seq', 8, true);


--
-- Name: icons_id_seq; Type: SEQUENCE SET; Schema: public; Owner: miniflux_user
--

SELECT pg_catalog.setval('public.icons_id_seq', 1, true);


--
-- Name: sessions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: miniflux_user
--

SELECT pg_catalog.setval('public.sessions_id_seq', 1, false);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: miniflux_user
--

SELECT pg_catalog.setval('public.users_id_seq', 14, true);


--
-- Name: acme_cache acme_cache_pkey; Type: CONSTRAINT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.acme_cache
    ADD CONSTRAINT acme_cache_pkey PRIMARY KEY (key);


--
-- Name: api_keys api_keys_pkey; Type: CONSTRAINT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.api_keys
    ADD CONSTRAINT api_keys_pkey PRIMARY KEY (id);


--
-- Name: api_keys api_keys_token_key; Type: CONSTRAINT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.api_keys
    ADD CONSTRAINT api_keys_token_key UNIQUE (token);


--
-- Name: api_keys api_keys_user_id_description_key; Type: CONSTRAINT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.api_keys
    ADD CONSTRAINT api_keys_user_id_description_key UNIQUE (user_id, description);


--
-- Name: categories categories_pkey; Type: CONSTRAINT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (id);


--
-- Name: categories categories_user_id_title_key; Type: CONSTRAINT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_user_id_title_key UNIQUE (user_id, title);


--
-- Name: enclosures enclosures_pkey; Type: CONSTRAINT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.enclosures
    ADD CONSTRAINT enclosures_pkey PRIMARY KEY (id);


--
-- Name: entries entries_feed_id_hash_key; Type: CONSTRAINT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.entries
    ADD CONSTRAINT entries_feed_id_hash_key UNIQUE (feed_id, hash);


--
-- Name: entries entries_pkey; Type: CONSTRAINT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.entries
    ADD CONSTRAINT entries_pkey PRIMARY KEY (id);


--
-- Name: feed_icons feed_icons_pkey; Type: CONSTRAINT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.feed_icons
    ADD CONSTRAINT feed_icons_pkey PRIMARY KEY (feed_id, icon_id);


--
-- Name: feeds feeds_pkey; Type: CONSTRAINT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.feeds
    ADD CONSTRAINT feeds_pkey PRIMARY KEY (id);


--
-- Name: feeds feeds_user_id_feed_url_key; Type: CONSTRAINT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.feeds
    ADD CONSTRAINT feeds_user_id_feed_url_key UNIQUE (user_id, feed_url);


--
-- Name: icons icons_hash_key; Type: CONSTRAINT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.icons
    ADD CONSTRAINT icons_hash_key UNIQUE (hash);


--
-- Name: icons icons_pkey; Type: CONSTRAINT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.icons
    ADD CONSTRAINT icons_pkey PRIMARY KEY (id);


--
-- Name: integrations integrations_pkey; Type: CONSTRAINT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.integrations
    ADD CONSTRAINT integrations_pkey PRIMARY KEY (user_id);


--
-- Name: user_sessions sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: sessions sessions_pkey1; Type: CONSTRAINT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_pkey1 PRIMARY KEY (id);


--
-- Name: user_sessions sessions_token_key; Type: CONSTRAINT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT sessions_token_key UNIQUE (token);


--
-- Name: user_sessions sessions_user_id_token_key; Type: CONSTRAINT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT sessions_user_id_token_key UNIQUE (user_id, token);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users users_username_key; Type: CONSTRAINT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- Name: webauthn_credentials webauthn_credentials_cred_id_key; Type: CONSTRAINT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.webauthn_credentials
    ADD CONSTRAINT webauthn_credentials_cred_id_key UNIQUE (cred_id);


--
-- Name: webauthn_credentials webauthn_credentials_pkey; Type: CONSTRAINT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.webauthn_credentials
    ADD CONSTRAINT webauthn_credentials_pkey PRIMARY KEY (handle);


--
-- Name: document_vectors_idx; Type: INDEX; Schema: public; Owner: miniflux_user
--

CREATE INDEX document_vectors_idx ON public.entries USING gin (document_vectors);


--
-- Name: enclosures_entry_id_idx; Type: INDEX; Schema: public; Owner: miniflux_user
--

CREATE INDEX enclosures_entry_id_idx ON public.enclosures USING btree (entry_id);


--
-- Name: enclosures_user_entry_url_unique_idx; Type: INDEX; Schema: public; Owner: miniflux_user
--

CREATE UNIQUE INDEX enclosures_user_entry_url_unique_idx ON public.enclosures USING btree (user_id, entry_id, md5(url));


--
-- Name: entries_feed_id_status_hash_idx; Type: INDEX; Schema: public; Owner: miniflux_user
--

CREATE INDEX entries_feed_id_status_hash_idx ON public.entries USING btree (feed_id, status, hash);


--
-- Name: entries_feed_idx; Type: INDEX; Schema: public; Owner: miniflux_user
--

CREATE INDEX entries_feed_idx ON public.entries USING btree (feed_id);


--
-- Name: entries_id_user_status_idx; Type: INDEX; Schema: public; Owner: miniflux_user
--

CREATE INDEX entries_id_user_status_idx ON public.entries USING btree (id, user_id, status);


--
-- Name: entries_share_code_idx; Type: INDEX; Schema: public; Owner: miniflux_user
--

CREATE UNIQUE INDEX entries_share_code_idx ON public.entries USING btree (share_code) WHERE (share_code <> ''::text);


--
-- Name: entries_user_feed_idx; Type: INDEX; Schema: public; Owner: miniflux_user
--

CREATE INDEX entries_user_feed_idx ON public.entries USING btree (user_id, feed_id);


--
-- Name: entries_user_id_status_starred_idx; Type: INDEX; Schema: public; Owner: miniflux_user
--

CREATE INDEX entries_user_id_status_starred_idx ON public.entries USING btree (user_id, status, starred);


--
-- Name: entries_user_status_changed_idx; Type: INDEX; Schema: public; Owner: miniflux_user
--

CREATE INDEX entries_user_status_changed_idx ON public.entries USING btree (user_id, status, changed_at);


--
-- Name: entries_user_status_changed_published_idx; Type: INDEX; Schema: public; Owner: miniflux_user
--

CREATE INDEX entries_user_status_changed_published_idx ON public.entries USING btree (user_id, status, changed_at, published_at);


--
-- Name: entries_user_status_created_idx; Type: INDEX; Schema: public; Owner: miniflux_user
--

CREATE INDEX entries_user_status_created_idx ON public.entries USING btree (user_id, status, created_at);


--
-- Name: entries_user_status_feed_idx; Type: INDEX; Schema: public; Owner: miniflux_user
--

CREATE INDEX entries_user_status_feed_idx ON public.entries USING btree (user_id, status, feed_id);


--
-- Name: entries_user_status_idx; Type: INDEX; Schema: public; Owner: miniflux_user
--

CREATE INDEX entries_user_status_idx ON public.entries USING btree (user_id, status);


--
-- Name: entries_user_status_published_idx; Type: INDEX; Schema: public; Owner: miniflux_user
--

CREATE INDEX entries_user_status_published_idx ON public.entries USING btree (user_id, status, published_at);


--
-- Name: feeds_feed_id_hide_globally_idx; Type: INDEX; Schema: public; Owner: miniflux_user
--

CREATE INDEX feeds_feed_id_hide_globally_idx ON public.feeds USING btree (id, hide_globally);


--
-- Name: feeds_user_category_idx; Type: INDEX; Schema: public; Owner: miniflux_user
--

CREATE INDEX feeds_user_category_idx ON public.feeds USING btree (user_id, category_id);


--
-- Name: icons_external_id_idx; Type: INDEX; Schema: public; Owner: miniflux_user
--

CREATE UNIQUE INDEX icons_external_id_idx ON public.icons USING btree (external_id) WHERE (external_id <> ''::text);


--
-- Name: users_google_id_idx; Type: INDEX; Schema: public; Owner: miniflux_user
--

CREATE UNIQUE INDEX users_google_id_idx ON public.users USING btree (google_id) WHERE (google_id <> ''::text);


--
-- Name: users_openid_connect_id_idx; Type: INDEX; Schema: public; Owner: miniflux_user
--

CREATE UNIQUE INDEX users_openid_connect_id_idx ON public.users USING btree (openid_connect_id) WHERE (openid_connect_id <> ''::text);


--
-- Name: api_keys api_keys_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.api_keys
    ADD CONSTRAINT api_keys_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: categories categories_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: enclosures enclosures_entry_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.enclosures
    ADD CONSTRAINT enclosures_entry_id_fkey FOREIGN KEY (entry_id) REFERENCES public.entries(id) ON DELETE CASCADE;


--
-- Name: enclosures enclosures_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.enclosures
    ADD CONSTRAINT enclosures_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: entries entries_feed_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.entries
    ADD CONSTRAINT entries_feed_id_fkey FOREIGN KEY (feed_id) REFERENCES public.feeds(id) ON DELETE CASCADE;


--
-- Name: entries entries_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.entries
    ADD CONSTRAINT entries_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: feed_icons feed_icons_feed_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.feed_icons
    ADD CONSTRAINT feed_icons_feed_id_fkey FOREIGN KEY (feed_id) REFERENCES public.feeds(id) ON DELETE CASCADE;


--
-- Name: feed_icons feed_icons_icon_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.feed_icons
    ADD CONSTRAINT feed_icons_icon_id_fkey FOREIGN KEY (icon_id) REFERENCES public.icons(id) ON DELETE CASCADE;


--
-- Name: feeds feeds_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.feeds
    ADD CONSTRAINT feeds_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories(id) ON DELETE CASCADE;


--
-- Name: feeds feeds_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.feeds
    ADD CONSTRAINT feeds_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_sessions sessions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: webauthn_credentials webauthn_credentials_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.webauthn_credentials
    ADD CONSTRAINT webauthn_credentials_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict zoo

