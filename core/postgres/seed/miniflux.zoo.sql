--
-- PostgreSQL database dump
--

\restrict AQCEwbUFGqSywalaaAWkH5LfcddeA0c5hfmkGMRaovU5X5eXzCkcuON0fF4bgyC

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
\.


--
-- Data for Name: feed_icons; Type: TABLE DATA; Schema: public; Owner: miniflux_user
--

COPY public.feed_icons (feed_id, icon_id) FROM stdin;
\.


--
-- Data for Name: feeds; Type: TABLE DATA; Schema: public; Owner: miniflux_user
--

COPY public.feeds (id, user_id, category_id, title, feed_url, site_url, checked_at, etag_header, last_modified_header, parsing_error_msg, parsing_error_count, scraper_rules, rewrite_rules, crawler, username, password, user_agent, disabled, next_check_at, ignore_http_cache, fetch_via_proxy, blocklist_rules, keeplist_rules, allow_self_signed_certificates, cookie, hide_globally, url_rewrite_rules, no_media_player, apprise_service_urls, disable_http2, description, ntfy_enabled, ntfy_priority, webhook_url, pushover_enabled, pushover_priority, ntfy_topic, proxy_url) FROM stdin;
\.


--
-- Data for Name: icons; Type: TABLE DATA; Schema: public; Owner: miniflux_user
--

COPY public.icons (id, hash, mime_type, content, external_id) FROM stdin;
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
\.


--
-- Data for Name: schema_version; Type: TABLE DATA; Schema: public; Owner: miniflux_user
--

COPY public.schema_version (version) FROM stdin;
110
\.


--
-- Data for Name: sessions; Type: TABLE DATA; Schema: public; Owner: miniflux_user
--

COPY public.sessions (id, data, created_at) FROM stdin;
ADwTN-x2pgZPDIvvKxU_zvPh29wFfrpuNr6FaO_kl_c=	{"csrf": "xXxzs7hElgqsALD49R4sghyya0TIwrzTJR4HN9uwdFHKC89nfor8gCXMbVfm0496kJv7DyB6JtXsIF945b4bkQ==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 18:41:24.306411+00
OnCDpwI8ChXPBJtryRSyJBLIwtzAVOAAsWyso2BH0yA=	{"csrf": "5nsXcfQuUPax1oKqQL7bNw7elUTgNUDJeUvC0EFQaTehQj1ZgmzuKh0jGI3FceKEkqWLnCOhgoOVD-3dcsOxHQ==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 19:23:43.176796+00
fw1cdogn_Cw8udlSPhRMOK71gBTOh6_oA-cPKTxA6O0=	{"csrf": "goAHcokOyylI5LwYgeQY7IOvrPijfkob8fll2_t9BYsRzEzk1ohiEmkObOAEZ8yfJJeyrgx98uUf_I1OccuBKg==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 19:23:45.95525+00
uM_EYejvStpS1dllDj8Is8Wc5pjEwrGW-Ofpt1RL1fo=	{"csrf": "oS9mvwwwkYEtjXcGAiYKT6kvf1GdlaLzbrI0EtjhspPpv6_CEP60NseepsqbMhCt5NCuUC1Ep0mBNG6-Z44Dag==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 19:23:47.039748+00
50MR48uPponVEk01gNlUnaz5Y5jV1eKWt0_N9v5z3WE=	{"csrf": "PdKy-fy8I6oXCUViMdZ7TtZE65-GK4SKhR3ZYQ11bP1LQ5_szD3l0rr0U4a-DrscvpJoQHD0j2obdae0lWYy-Q==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 19:24:04.127888+00
-ALflJVL-2OrFzm2Kt389ym1o_kAdvLkuWZPEmxH_8M=	{"csrf": "H2fvFVT8NYlXOMvN5vZ9MyjehuZSTyYyTEtQWfuGNSd4Dgb94yr3XAQC8A60RFVG_gUWhCfwo-PefJ9BoOBYqw==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 19:24:06.982126+00
HW8iLkiZoVCBV95AGPyHuEOc_R_Txx0vB9cg-DRi-cE=	{"csrf": "jdBdSOo8z8NUPR2I8Wjojnb_gp8ZwZNRrqoI5zyNlfWcjWwAbKlOiArS6aSowZLOVQi3r8Or-jYpebbWuc7hzQ==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 19:24:08.421419+00
ppdAr7bo9rfCmWj3FVij9HKg4lhu1BXwsjS-6BNV8tw=	{"csrf": "vAncR9QAjhf_CdY705y47hhOntPA8S8cdMjyepCI8cHEsrz5Q9Qig1E8r0l3m3YlNHdZe-q1dOd35ZdLRSYkQw==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 19:24:11.359237+00
gGlvgUpo01NSLf5IUQXxou88puoyj_TCR5Cg5-KKHD0=	{"csrf": "YaGBwgwqRLE_zuqVOy5xDEQDwlg6G6jTFokBYetsGqSfbS4Tc3Iw_5qM8IUe3_YoLgqAlcNBSJ7rYLb3NRkjDw==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 19:24:11.456332+00
8aQFF_KFXq_yvFMyczvutM8TBN9n0hMGuItx7ZN0rv8=	{"csrf": "oPP6uyCH5BCEFb4nwXFRNTtJcht14i68YmKFj6uTat1wA2gTEavdEQdA8mXBf3v7KtY149KalD_IU89W_t0Qrw==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 19:24:11.474679+00
zqiq1TqHAiba-5GdYwCJnuLvwKLqJezza8Lpf8otTPk=	{"csrf": "YGGun0H1lcaWIsXv1wtK3PqHOiMdJ1bH6Z6Yyi8Vs-8sTwD0u6nEpEKVxlJr1xNQjwW6a4bWlX-X0xE1tJIoKg==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 19:24:11.540241+00
3XykQGvt9_itcA6y0GM4_AkPGaw16gZMfwOGz4yJm8o=	{"csrf": "UeJlQ5KB4JPIzYH7KllQgXIA9gXgCyuS3bz8gVp7S_9DhW-Hzm0BroqEah_aaRLuHPd3iO2NuBYMv0EC8AB9rw==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 19:24:11.864262+00
5qjX_CYgVU7ndyoBaABaW5nUhlhkr3AIo2LNRxJcT5U=	{"csrf": "hgYX9FqZ4T3aS9c6e_Px1Ks7mukLsb_kCL0JySdVOdb1O_jnrw-ObjUeT6Go6hKBeHL-Jmunx3ZwoeO6aBAhmw==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 19:24:12.409184+00
Mg6myoNqG21PhfHv40EBXNSj0XwP2Cr166R-DMydCXQ=	{"csrf": "pS3VIcTHtC845k6DrY0lNZDaZHnXI3jKCuzWUJlB8C2KP8sOVnsXKMz2fBLACbsDS6VBLZrGJ8UyHxYxK6bt-g==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:25:37.064492+00
KIq2lQxO-3VPOsa-5GsU6rvxocCRTEsnvRRfkxGmIPE=	{"csrf": "m_KYwJjqtS6zg41juVKwgWIi_MKCxvnOhDvc2fxbsLKk7jjsJ1-Zu4wkQysOR0YcZTVXrojn0U2GGVwQ85t2Kw==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:25:37.074746+00
FOK6I-WGwVUVO8YOWR0siD2f1vHQJvlKyewVr83QF98=	{"csrf": "bYG_A0xJspVzb8cmi2YxW0fPqM3w6AX9B1mD_rq1B2Jb1L2-bNCi88Z_V8AxL8ul6yV1cvxfjMF4UZD7PMeOcA==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:25:37.789565+00
FXiXf3s-3IMYfxfQwklPUomfxk2rmJLnSW4NV_rZwnU=	{"csrf": "NInaGzVD7jAPnyoYweeKsiH9JlrhE1B-nw394cD-V2ustQ24pHmEM3lgQxu4xofJoHGjIVShM1TM50Rq_MtSMQ==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:27:36.991038+00
Bty-_4iA-nSZl3NY4wLGujLLkJvorfbKni5rbksBjmE=	{"csrf": "gtEFmmFCzblfd6dHkDumgRT89CrlwkxeBF3nfZNfpuACDKTX4I1WEt9MtzFJwc0SBu3msiXaLE3u6FfxL_ewfA==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:27:40.150964+00
W9d5LX1Ofwnlab7svguXc1NfoiGPDr8imtRPRMEshio=	{"csrf": "R5P50-T-b__3oTG_vcKCh6OGsf63rvAEjUg4kMz1kEQRbsqZjqPzJXsYjNWoScD0_6z-qvGkGBdzwmKZtHn9Sg==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:27:40.676078+00
f9e2KisNaAyI8QjE3xPvPHqQHNhWv-SddGrtThnUTS0=	{"csrf": "8m-IK_dDFty5a3vT__p8w_ByfoAbdvOZjsequbN-L2amnGN19IqMpL5BrqIZoEvEK4LUyLy_d4HE77zVI389HQ==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:27:40.73081+00
G4XERNSSZ0TNKQYSn3Ge4uQI_EWc_AAetD9EFBWKtTg=	{"csrf": "liZevXpkLIEH3vZCA8CeaZOVO_lQ0zquRox5HmYf2il-08YjoDGUSvoA5thaSvIpsXR3OitgytLk5MbJf8PVoA==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:27:40.743607+00
5XnnPtZD3bOsyoZtE3OgBLJv5VFX7_IeZouheQ0O7l0=	{"csrf": "C3CQFP4lLa4OWXANEjRwOd13u_Pz4k793GWD_6I_lhDR6JJdrZzfy3FAy27y_lQd-QGkFUoYvneaI3d16qbepg==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:27:40.752409+00
vKHQ0tv_ei0Tk_WVQMsX86PAR_zClz_xg6uMMiYclJM=	{"csrf": "acffy4Fh5GeSy0BvjAoJyCX6HfvWbfpv-dZ0OsBGr7lwwYkJI-C3gcvi2zrny42sKDWDdHxHhtNui7j28KnYIw==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:27:40.796105+00
yjF2cGYNIWNEKR1mnRzLZNrpwmgWlK4rzQaqLiDU4qs=	{"csrf": "76IriIzfRNMv30w1NxczBksEex7hHgnYup7OUjLWa2Pjl5nbfR1WlaPQnvu74SpY6XPuAryPgSwYduGXXpetFg==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:27:44.128732+00
znZJwZ1wdeRgJs9WWrSTXVEODim3zCIbyB2k1F7Qaf0=	{"csrf": "C5aT9aYK7eqBcB51z8z19uOMdIxVIWEe1DgRk59KmJYoDCRWf-816iZt5ybnsurwrBUILowOBQy7fceFhmk-fQ==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:27:44.248909+00
Rt7ps9C71GUQD8nxorZ7pgMbjFQ_T5xvQd2DOTEpRew=	{"csrf": "rOkvpYPZLAvTtIAM-Zof4D0TSE7WyQPF0xNY-TsRMGYscujAo860njhC-9OXtvTkoJpKLNKfsn04IK8UeBtumQ==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:27:44.271449+00
gT7Bhl5F1ubSivWSQi9_YFsnolaUwC17LcS4Kg6FzEo=	{"csrf": "sgr5QmR76Sp1LoB6Ivm0x58iJPViET7znc4pE_vEcDcQz4-t1IrM6-iWsLrnXXkS45aFWnNdXl_kimnfrIylGg==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:38:56.759738+00
bOYrJiX8jaMgi3zsi5BSnWseqwHamhGbkkNf1KXsYAc=	{"csrf": "gVxvxrwY5fZPydX9GMhLe-zp-Fq9hel2SoVycHIM6nYsCCrltjfdtYaOMkTVd31FvJQpzECRA1M09ha8YVo3_g==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:40:03.401427+00
q2d2hcDDT2JCG0gyebBtEBcAaglKFC8HGmIBdVFxSgY=	{"csrf": "fAiiSdm39ujkBa_2WPiiMq7kpbxj0v0y8Hy3huz5crBfAKEVhCyMj37c8QVJV3-27lH70BnvpxPuVv19iWUMJQ==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:40:05.519901+00
axF4nxPjXxij86tKZVHv_RWOTzYiQJGj_Q53tihWNwE=	{"csrf": "3b-WS696cHuQq-jtu4XfGkjGktIMMPR7C6jnRJStbRJZjX7NkP4j9qOnuxHniK4Oh16a4gEVuKAWLRpbRO7CCw==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:40:05.759568+00
mL9yuUC-h7vbkhcCj4C3cfxnQa55550CAgUD0i8Eyhs=	{"csrf": "YN2Wfpb7k_bzhEg-h7IGyUQMD_kV2JQUbWo_Y-Z56EaDRUcaIZMqLwigw_IQecEKqSmg4XDvtX7J0uOybqtUYQ==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:40:05.764639+00
39zzxbsKkOvSrBTaY0cozDtZXqLPyG5Sng-FxECIhMY=	{"csrf": "g9DzHtVDUCczWRpPrJXvApzae6vSLvDFqGeqBh8Qqk_5cc5cDE_5ME28zTUYzqx28BK9sOzE5b37b3Tjvntr9Q==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:40:05.775786+00
9ihRhkg2Lv5Z8ZLPMP7OmdQMmWzj5kOl437zKDV9tX0=	{"csrf": "81iiGWOZ6dhbn3xgdD4MP3W7pzqPaTRJZw2qeZZd4mDXbb9X9vTT377PcvErtENYoJuyeO3EQZsYOSn7qGZUng==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:40:05.823015+00
ASZGjWGgKIBmAtpw9h9I_EmtUXacv5ESl0XIWYB3C0w=	{"csrf": "Pet27lzz36vyJaforFJA0T0fpn-c-otLQzAOKmO7uTFm-rlrCqDe6ykmcmE7pICmayTHrkHyzl8mHd88HeCdwg==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:40:05.835716+00
Jk7ACY9Qg8-JlO2GGBHbdS2UosoyCAuin5_6FkFhtgQ=	{"csrf": "2fMrIIuPf-qSsOfSUXKenGNEIkL8-6LzpHgleyPPLto2f6pgBkSKV1A5PBCP2S2Sw9fCXjn90jtIo0zVKg_hZQ==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:40:05.83569+00
KRliVoX8BV01ID4q0CWAZ0QMfxoY33eWcHSIovcJ_zE=	{"csrf": "vaSgD6bBTz7zxJ9aL3WkOcc_2ww4WK1vmkcQofC490eZwtfK2puvmMQ9kqtucApqRPZJlrNh7dzSk507D619Bw==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:40:08.446812+00
yceomf6S6BdT6LGR-LyZune-Gnbg4BB_ZzLJIhynHgE=	{"csrf": "3m9a1VtpQUHXtvsZ30DL9rwsYJ0qTdRQiV90oaLswbeKRoGlQaepI1TokWZ8jxmLmljDFghJMwrFFSjrhpOOpA==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:40:08.779199+00
gZw4Egg7GWDG_2c_oYQUQjUADmMNrVWmLAh4IpAnzMk=	{"csrf": "szTEzifBOddTKVY0dEkmEdeIk9kgXZJgHGaitTRF5uuyAf6uqSHCYhvO8Jh08WuJLq7xXh7_eE3u5yxmkOhukg==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:40:08.804335+00
ZnCDqRjWlCOr-IEZ4Ydozei3zbc9AB-edXPjjEQWpQY=	{"csrf": "Hixdd-L6e1OueJx64_kyiUrTT5hUgjWfUzP6_vm3mOOKgMQpDoy74tQ0N9fvdFhVxVPxLgjSTWjEa3bOUJAgPw==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:42:43.064048+00
Ngp6xD8Z-zOqZ5uilefW-hlq2-fFOrnpvwBAw7HTUb0=	{"csrf": "wx2e0ah6BQ5j-ES_xdGgi_DA2j5AT5mrswHJdadCmWAaFQNYtYIq3Y2pym1VkLtn5hMWBOQLqcvd-TnmLExTwQ==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:42:43.418971+00
DuF7ei6jibzp7FEkewulq54PFEgY1MuaL1AeuqM1bY4=	{"csrf": "zt5Mt8gknOtUpEHt1ntDR2YScmqHVcg8MVQktcj30ZKN6w1f2FQokFvEBN2-0JOjyrD3uCSz7QOuPb2rFnUD4g==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:42:45.753512+00
WG7NT8s7MFN1021ObO17fq1W3FYbWv_REXdbKQG_6A0=	{"csrf": "cqEB6X6J_x-KiflCFLqDcr-K6yhcpcvv8weHx3Wgj2JnMJr_ji9aIOPxKnJXNNsfIBj9JPIMxg-xRaJzyC-6bw==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:42:45.869474+00
AVkvwutpsaf4OpeCOWPR6yPzyGqTcf5ytrBSXKG5BCk=	{"csrf": "dyO-OQPm0aJTmwMGbUnWu3UvWNHfHzr2cp19j_rM5qIg50pxUHIe8Tv3M-Te3rqyzqtmXFF0MAS7wqUeP7UVAg==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:42:45.916295+00
VIuGAlp1cy4Cc8H07W-n3TZKMoXW16Jid4iPwANxwuk=	{"csrf": "Xr5KInY0wf77VVbMDVosAUTYlUWkmLVDdBa60GWC7iHF7Hmz_0FgOcxBFAbbTd8vP2Cfx73MXSp3-HTQ638QRQ==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:42:45.95259+00
ftCqGM7hSnH4P3qHsnXOx4tLUq9uMz-biido-uo9DOA=	{"csrf": "6txyr1z-bLy9S_pKq3I11WO_DCK3qJRZ2NZPdZeKPIfxRVW9p7IzaQMAKzp8nbr3cz3FZemVk3ixCgL8hwS4gw==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:42:46.075706+00
xbQeJ8Ba8q3yWz5lovliFRdfLpsMQgAG8vfiIqzvZjg=	{"csrf": "WG1sd4NgYqMCFC1_WDEaomHCzx8hD2m4M_SKKcH-Jlm-Cq6MQr693TYqIlXZIBNkt_5hfDQzHtcEwvr9EeoYOg==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:42:46.172879+00
t2LIudLrAHmGQv675QSdup2Dynkpc3KtEUKBJsEXe94=	{"csrf": "3vgU5lTcto2VFCFx8eZDPe8tmK4VuvgHXDs99Fi-OLNYPQRxghzc1fOKZzxLHh651dqqAzuU9t3sKquz36tLgw==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:42:46.183634+00
XtWambgrQjqn-zF4_4CFeBDjNsfIWG3Y77rmxHDtMqE=	{"csrf": "skfzXg0_4XYTUXAcpaQ1pKkzOkga2n6GV4B-tVAHd7Pl-irjjW8Kopg2fRBXv8VugzDtzjXLQN0aEHSlgMe75A==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:42:48.435471+00
3jE2SwFfV0r_VpkghGyNmlaoyxRqs89vN1T7FnJLTGs=	{"csrf": "UPm-0T08YQXySq_wvVCivVCYxdHQNt8rWnDMthI3Cb-i7P9mIXS8QWS5POcuH6PW9PVfU8TvE_90hm6BUIhC0A==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:42:48.551136+00
lZmHDYkKxRceC0aS5C5Joeq76KSMeah-mN8bi1WRsq4=	{"csrf": "JsDa5P7x050ctjnKxltEABCYMetMCtjvymozlFvr1PyzNc54Q-qP871y4vmgg7JIrnQDaDfBAK1WVs8emiJquQ==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:43:53.496559+00
QftKm4YKBs1-Z7xF4zbejybN6oSvqVc5vGXW2VverkA=	{"csrf": "YrvFPcBGUeNem90wkbUYV-d7AulrjvfbRJqYJ0USURyi-aoxoJXch5WijtSNeYNfGxfe-r1ZA6B9Yobzl42puA==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:43:53.505624+00
hR4eHCG7wOAapzOWdYR-Fsgbj5YIMjk-Fyrp1u27rm0=	{"csrf": "7SrHSIHp4lByfMgD71HqN8juDXa52KXAY9LpMighUiPjllxNb0Bl-XwWwjq_joMWz4p-_XnlYYbOsKJdtgfhUQ==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:43:53.930141+00
hwxsYtCmLIZdokIXs48fzgLzMwe51zZ_t_B27iX2iUo=	{"csrf": "WgJ_WuNgnHVGC3txPSADkJvyLZHCFujj4INiqnf-xFQD_oshwvQnKJF5WKE3JKrzIhaZk_k8V5Aqxlx0qTpmOQ==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:43:53.938292+00
yd0tLbz-x5arTrSBzaMCnWaXAGM93PklPtRBdoBisEs=	{"csrf": "6evCjUqTn8bAqCzp9wPEohd1E8pOV-X4WR1f5kTjtWW4ttl9Jl7C2jfFJnXydbqguHOLNQyqksTMMp77-vKK-g==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:43:53.943217+00
-qzkhBnvn-LMv7BrRDAfkwALSsN-jcXqIPRjWntMrKA=	{"csrf": "gT7fCL0KMJ4Nkmuy0NqFtkoutwKUNOR-UHU0FP27CkVhPN-lfbWS4n58r-A170Fzx-A3uvgVP9Uz1OQGpDReAg==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:43:54.011987+00
OFLOWl01z7FRxNNVZaEND7DzoYRUNtu4DVNMS4eZGnI=	{"csrf": "_uJ5AVEYL2SQImKEqQP3gkDehkJ3oRrKxWELWFyqEpfiZEpvBGU_iK3i6l4Cq3TbkFpqCuEYDA4x9371rFBfpQ==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:43:54.07037+00
6HOdOGwS1ACHhKS8KmUrrnZdPrhoaJstmV1bc06AmVY=	{"csrf": "9-f0dvwxr2-C553utinWa3Zy8p7Qi-l9PiPpkJZHcQ0lVFXb6R3e8UK-ZxpL6PR9fpw24nzqJYOxp2axi9QMSQ==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:43:54.077674+00
U3UmA6-k_DsMQ4zUBnNxLiSZwdOjJ2Cuc5E3dVsU1XQ=	{"csrf": "s00YmKsDbqqkV3i4finCbgYipYfFAU1gpbeGnZoyG05AAadKA-OI1T8TUZ9z892OVVIcnkuMaLPKUQv5WtBytA==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:43:57.091417+00
XVs-DKaGhGX-mz43f_qfeLjdJoN971d0fZrWQwGX3TM=	{"csrf": "by8i7WEpdw5giS33rabBzFdfrX4p6tsb1rs_v4_0TC7w9-Bx9NEXdDc110acX-OjgNckCPvqS5jIGnntDgDfhw==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:43:57.695599+00
3-WPU1XpT4jhrxTw2eeFY99Fbd2rPFueUJmqDTZqzMM=	{"csrf": "ckKQckRCCioQwZY76I9kyHd4BMl1Q4xveu6EuZnLcoiuYl-9tWBQZBjFFqlwfLxwphqZxfMkjfpcR1eIjxOhKQ==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:43:57.814473+00
ygxsiizAGLqraHX5IIETNWb9SFM7dmAXzq7FNLXj5h4=	{"csrf": "pCmH7RlezNwRTY7a8YTACiggFClxOEko_F9P65xQmG7jo5RqDAFHrCJWqsVbFzYJ7VhQcgath4UaYOpzodORIQ==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:46:39.477904+00
TTUvS2GfSHiGDiAcQEND-EHHLgUtZlcmTiAn5Oga0qo=	{"csrf": "icH0o-OtmUh8FjcVN-6bpNHpwxQX8Sq2vP6MbK6Kh5aVWiZOwgJN3eh1UGABXhP7ZGRDYrV7kZjhgUtxOLKqSg==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:46:40.18546+00
zQEvUSi2ZxHd6CqUtOo8CZqfUl_Aw3SSa5VucE9mr4s=	{"csrf": "0D27j9sxFUADRMkkaNBaVtglvtXpIo12tNwfN3-u4-6s70TOTPWjrB_QREqtCfruleNDnp91dO5MrscuUICYtw==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:46:40.279215+00
BfDqKAcwqRWW3jSgVAPIZW5Qr2t8mLigEXIKP96VhLk=	{"csrf": "E791NQaz-yOr7NLgc0P16SxpkOXsjKt81zNggbmlSo_x5YCCkEjIWlHGTFGyDpG6gryrowHJUAbG-XiLogXSzQ==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:46:40.300618+00
JNk9Ngx5DoAa-Fe8sqaFGL1nOqD-pQC41BxN-Uitstk=	{"csrf": "yGBs_Z_wGoGXEMRXk8u0_iDU-0hBZCbwDHU-jy_ha9dmSVojFPYMMjlJCV1P_B-Q6zTQlcU3Fu6npC-Q_4oTXg==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:46:40.311045+00
pZHT-e3DzjBf6UzQvx6VOY1lMvPtrX2lcKrLn1amu90=	{"csrf": "kJZ5iSdO0Od4Tl4D51SrneH8Fs3kh1Y59p2-yFknuevLIe42lnL178yG0QEOl-IyNv8hZcRh6HHjNwKjaaZYeQ==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:46:40.419908+00
q9EL1X4repM_m5z7JoNPG5NAIWbVc0BC7cAeb7POIzA=	{"csrf": "U2X2HGH2EWQLxZ_1J90Tp7As8lYCdgl_bS0OKQe_sy5MwX55uutwgPU3Tw6QwqsKqY1Mp9dz0Q_vcRj8JNrHMw==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:46:40.4477+00
PeDZwwoxLyR2mu0vbJyuX6FrFWFMnPCZizv0P-BcZIw=	{"csrf": "B7E_LZ4Hu0LwKlQCQ8fvlIvgKEMU2g4VuMs37PlBXvpbJLBz14RbjISlAzaoGvXuCDttHp1jPi85KEJlbpo5fg==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:46:40.448267+00
P33MwM8vVSeCJLXKvWsoLLpYmx5cZEHe8TpNrex-yCE=	{"csrf": "icl-j7wLlOfgul_nIJ4HgnzHrENo-mPjSM_TqirYmFnQir_bx9IKpLqWcBN1g5csojv8mCfbjzvq0CGcqXf9nw==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:46:43.559628+00
xzAkaUzKEgZLlnT03mulnK5RSkAoygtKGbEHcbOgE9c=	{"csrf": "ScUS7IfXJW3cb7laI6cYdEUBXiXTh-WHqSnqabtc3EDDLN3Uay_v48j_kfcOuW1Wp80JFhL1exvWLjGmiouSvw==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:46:43.690939+00
k6ZEpOwh5StAfQtTQejLGBUQUBoOdkw3fGDxFZahRjs=	{"csrf": "_Irxdhd6qpRtPBaiwLWIYP-0pHwgJhcWvButrlc9x2UPPCFkvSFlI5Muxm3ffgDrycrxziqSZDw7A-LDbk_Yhg==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:47:19.06447+00
jhc2Qaf8QabVrTYxuFbMD7f7eqvM8jsW0WE2vjB9WlA=	{"csrf": "2eoRng37pHGZYeV5jPCe295FOGfaxmauGbVj9G-D8JnonyqOsvSA9U-EXhOxM7aJzV4XN5ybXb-GQe13O1I8tQ==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:47:19.132581+00
5On6flMyufKpQ9Y5nLc0dGMFEjQoVJBeoAXhgScTmWU=	{"csrf": "uSYa6n3xqYqdwqugaZRYk82UHdW4MnvMK3pMXT9FcUmDg9WgTH4whljrgx4r9WT5C08zNGcfQFrfM2MhWZ5WDQ==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:47:19.143085+00
aEtQGdS80F7LSUg3Q4HUW0QNseJ1y-uXz8iIUgud5aA=	{"csrf": "qWneANkQ6x2Fkc-pKXV6FsgAa_7PKTQJzGgVdEwmRIARjwoM_xeAoLWudC9hCiazJ7q3ftWgAVX8xhCTBV3_ww==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:47:19.153537+00
MHmUVHjwM60rg2DH_jpFYzccLx5h8Uy5aqkWFjnlL3M=	{"csrf": "I37LrnPxn1pJmvxVsrYtRfcp8ZZs8CIk54KdhSiBcsEmoBWik5GX0Id5LG9dv-6YWSwSOkeLnewJhh76ra9o4A==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:47:19.227985+00
K9TcgjYgJWFr3zn7caN2CB4pboOJFCC4CcO7Bq_vvu4=	{"csrf": "VoBBFz-KBWeMUEek9u5jDzuqFWQ2rLtRfmFnS4PYCsD5Jj5WNrSr8VLfUF8cek2b6ytdpq789JFP2ustUKWsaw==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:47:19.25987+00
D6CQYdeI7ulwT25vekBrr-vEZZnKmlJ_-ljGcFUUZy8=	{"csrf": "7BsVrQs1bbTM0CyN8pYczK0Eu8Smh3hxbOs1_AQ4QqtGnj9Y9WEQjaqLWND2D9vCnGQYTEBbqJzY5Ldv_soMbA==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:47:19.261738+00
VFnt-QojtCM_rYMjyUtSPBdxwsigvhxqBjkOH9txsRI=	{"csrf": "ZrVZ0NNsno6gP-s4PoN38zy0kwAlmjOiCNd6MznOVKHJR_PbB5klduKVpme6s7tB6s87orvXoZsvDIRkM3Sd7A==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:47:21.435286+00
PBZUUCwKqFSTw3KVEXyrzIiD6Izqx_0vEN3XemGRQkM=	{"csrf": "n1gkLfGSGIRMMO0GeHn7EBcOF9jVzyQNgke3TLtm8NJKmND1X7YByUv4lR8sQs5EJvIFZYKKb4IX3bi36-SPbQ==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:47:21.531704+00
dQVLZXMDwsFWQyKuEgCUhU81c205Ey11G-zpb3kWBX8=	{"csrf": "mcM0OusbsCx3j9OWMVHjj8peehb6A6tmGCxianaTbosEpz0s_kazPHePwPAi5VRc7P5m5cTJE4ryo3g79VqPAg==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:48:01.677042+00
nyLC4pcV2EfDR7Gk8Wnj8b7IIPmP0SvNzJNj_qpCIhI=	{"csrf": "LnD13c5hrOZ1A4TCBkfU2RpnnxE24_zlNEaHm5PL31DDZzSLDdRl0q7so9QD-zetDp5jxPZj4INl5Pc_D9F81w==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:48:01.791495+00
iGWXfng0FXKysXRSnH89VRIeVr4GA8FCVtE0HYdgBjw=	{"csrf": "79KLWpUMyNOmDzH_0CwqPKwjq5_tyAQkTWBVERxXmKqXZJ_efk9oikvNWrXXPzB0eT1UtFyi5t_JU8kbl8XqGA==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:48:01.831512+00
76MdStMHS1QlgMzsztH5tNuhMzzSoq_DexqvaHBG8ZA=	{"csrf": "uAb8FF_su4GvqjnGd7BKfVmWyPX-lYzPtbqyjoa-cNhhTAuAbxnJVPVrFRUQtUAzKspTRqg1v45ThTj13XOuhA==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:48:01.843728+00
s_yd0_62-5wc1Abq06LOSHzACszqKzJ3dtYwAhArzas=	{"csrf": "OyF2aAf8HMrGLKsnLOP-KqccTALwQOzeUcuEYg99y37Q457AokXMR8jpEYNfTvIOr_naWyWmD9z6Ei92O5wDnw==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:48:01.943693+00
slS0ok6b67MixIBGSHky6_b_Y6zIDH0aa_uIeSHpRys=	{"csrf": "zgTApDuNjTgzw3kBOmvZA_iI2l54rxZbmf5AXS5aR_lmujfN2NdG83b8UrLB-ztooRtw8J6hZJ2VaUB2I2OFnQ==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:48:02.003842+00
KT39Y9q4LqvDxZnCgg_haz-AcQ6o0YMW0TXp7dU5Fo8=	{"csrf": "Ht6kp-PRJi79o048SgGlCBEikiOeJWJeUkrfMW0iwDqpdLKMZXZ0RvU6sOytxLgGGc8h7COK91pbNB9PqefaEw==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:48:02.012439+00
VjcFV3MjyHojmm87ia91plUr6R2UA5CAZaPC-WUafg0=	{"csrf": "sS9i3Q9Mt6MJX6Dole3UYQmVyDdTcYvO8-aadwekIlmk_DDkz2T2gBiZx8fQH9uEkx1YhkC5Pv8OYbPXvwoJWA==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:48:03.421589+00
d5Evuc2TMV9s6_srHQy9cQY3VwTay5JHshQ4WtSHIVo=	{"csrf": "3igjreGB4yZTi3398Ek2KPl-RQK5u3OauRr3JO405gQjvpdeplrCXavUxmuvKRLMDl6uxuGOmJHnri2bLm43tA==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:48:04.315352+00
KmTZdgVUC8j5DMCvel_mHKe09ceqvAAkLmO7s4wBlwQ=	{"csrf": "D5ilYBUMzh3jwV2Hqa2FRjZ9FIO3E2tolBRbF4SPNJFcJI0ocDmbNA2lbxEeVR9RmJxTRmsj-sYL-Jc4-99RRg==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:48:05.230268+00
xy-m5u9MTexz-M2Z-YX-RigT-50Q6VaURBarRS9UmTE=	{"csrf": "6v5TI2ULyKdsfKoc2KDT1TqNYSKgWK-0JkcCcVFeZBe-mmXzjq5tzKBJ885-SueNIpJimi5FvMIoYwN-vLYuXA==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:48:05.345422+00
-QP57wv6HaRIm_ZfaBEJQGASkUJxF8bl2q7juLjmNdo=	{"csrf": "0375HNOt5VUnzch1WN7WL49Ei2xKU5kwfKCWgyHOkCwJ6bJmEJsc_zXTbQU7Z0F-4MZ5DIP6e9CP2B8us62sBw==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:48:05.368111+00
VABX9EvgSyv_uAMbcPqi4xk8DRWcCV_XFkhv92udycg=	{"csrf": "g9lGt9kANbMisSwowEr24QM4evdgJGA27Bvmjf0YENalfA-3NWc7I4sdtgvMJNKKcFiuX-22O_rDEguThmRkEg==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:48:05.410797+00
DorQOaDoVy4aorBA2YatTD8WuTEMUXUiJZlTnf5LbGk=	{"csrf": "dY7VUr66a5gygvcNl-nyQKil9GyKWWlFmSm7iBSvqQkUKvDn8b939p0H8-3Dg4bL0Dli_5F0KOKalNGEsPDMaw==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:48:05.568219+00
Oxi8LFIcMc2EUErMrAgR_9FJwrnvPe6Ym5ZE5qblnbI=	{"csrf": "H5DNsE_s_V4-DcUn0o8LPnaHAHb7yEnUQ_2r4W_SbZS1OqqazkHTgxK569CdFlXxx29c80stcDYF_xA0R0biFA==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:48:06.896326+00
8JYwiSOjSx_CzOFPC_P-hGcu5H24jWCbcA7ojqLwSug=	{"csrf": "Vdh7cGpTQMLNVuVb1SD_Amf62Ci0ik5Gw0pcD9mu0f4bVyS6wbw3WQCz-iTieZvPo0_b6ttygU0oAWa36CIoZA==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:48:06.91434+00
IhxtzIecouy-OD1bt9o5Z_XNbL1nDmzCKnac3nF9aKU=	{"csrf": "MPIfg5l6jyTT8IGXlE1dQm0956ayYFA9W91oNnBh9iYSQ33Gzlrzxe_1Rf-P0Z0bhiNAFGTUwxPUV_qCym8YSg==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:48:08.212817+00
T-9TziLAM378vWKFb8PDyAJ_rWWbnlmiz4GS3j38wrE=	{"csrf": "KslmWKoiZvT-jxxYgdC6nm04L9tb5t3jYop3UpNEjdnMyTCpkkFb7hhKrrc6Dryk-i2F1iRJPd1lKn2r74rfDQ==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:48:08.546086+00
Rpfm3h-P83ivpKbPRdF9lxXp4nOWPmDV-7Fcp-3iNe0=	{"csrf": "c3Q10HeuRhfsHx_a4JbSONj3bzz9wCcb4gfTxHYZ6Ry3jAkBbAyRTIHzNzc1xECLwqmOu3m5gRT5vZObz60W8w==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:48:08.743703+00
93batLrSfL5uj7qDJmu-R-2NP5K9SqIe7xkUr8JodN0=	{"csrf": "hwXvBORR4BoBZf0lwXha-q6MlTRA1faPgfQSGWfnC9IrpnHUbCm7nU76R8UhNokrKhZ69egbr6uTI8XGeVSBKQ==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:48:16.040629+00
Qe3HhSfj4VWSaCPk-1Gj0YOOx5V5RtwQ0nyHnwS2p8k=	{"csrf": "Bd7yiazew2KIZtBrIi0wgx7ZSAsReR9-pW9ErZ50A4yWJajcSUhCEd8HodGUc944K5oxdE1p7JMSIP9uhPHCPw==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:48:19.21646+00
iUolt20v2pMT-S7wBUpi0Iv1plMYV2gQ_wp5-cBwwuY=	{"csrf": "HN5a85ovOtPcjnVOel58Qn3ar-U6LEHZhZayXLDjhzQSeDHWjMuqLDZlZBacZYyRaBjiMbs_5uJkg0uQTyjYvg==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:48:19.561219+00
Y2UCJa7xNX6b644zBEEbDLylvSG-Y2ATlWxzlgoArKQ=	{"csrf": "Z8uCptoptHMGGjpKokbudbsEqnmxHDASagNFJuH9SCB0WwYbRSS9IBJqY5ceqnzzP2YgbsKZAn6cYnsBw0UJow==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:48:20.868493+00
habAx_MujNwBVSdh2wp2IUwAYkDfI2TqkZy8u4a57c0=	{"csrf": "_RkeGWAfgm_g6jF64oyatTpKF9hZ5qXeQOH1440xDpXJI6w9-MfHnRjYEyz5nIu0FLhl9Jc433hfaseFUzIQUw==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:48:22.426399+00
qhFm4FJvRq79lES-oyFYT8rKEWNgUNFEfPcyNpTxWrY=	{"csrf": "ZjHV2UaeoLBzfsCX69WWHOMz-Vq-sRQ-Ah7QkZdxfFVJxafcRiBqbgrdnIpCf3HRJM2GQv_pLe7_FJk1XfR-Vg==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:49:25.855932+00
fi_o47FfdE3NbEY2ObApetjfPOKo4YtsuWADlM1-nBI=	{"csrf": "4pNYKusbIdQBiudQjnlfoSP1rvGYB6NyPiaH7cdpjKePWBNuJTPvcmO9FnksTOf0gBTZfUMEkmeHvVHquZrgVA==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:49:26.122328+00
sp0ssuE8ecJ7CWZnX9Rpi-ORA31RyiaL3odxE562KDQ=	{"csrf": "adz_gQldfCX_PlsrYM_fSV3GXwdfh1W-SJAoex1WuLv-jpd5LBrVx8X2NCXjfg6BY6L83p6ga-bSvgahpsG3YA==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:49:26.154082+00
sjfidRrRm4ByIsdVHOVAiRdvHO174LZE5wnh60eMO8Y=	{"csrf": "vRo6VhoSB636UsFk-IefxY2QnIYNgr4j1_OF6dS8xpuExSoDht7tgRmLN407T_4em3Uyzdhx5nfk8kRblmiKOQ==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:49:26.297654+00
udcJlTRCNhDcGSr4D3IBHUt-M5d7QZdgXU2PuqhxXj0=	{"csrf": "7ed6kyBbUBEI_2EYHEZm3V3IJN3DwlAxZAmxVuxM2mGg3H2PuECIQQS1Ds-hqqFiyRsRe_dgxq5zLt4KfqSPSw==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:49:27.115555+00
WD_EeCCJXk48E6btL3Z93BtcmPcRPevF3NC6YnUJgkw=	{"csrf": "aAv1uoMx9yDq57lbZ4brIVGhCBDj7DcSnpHu1y5RWRU0SkCfhrr9O2v8UjE7iTY_v8lU7clTHUzvy96vpLZ4yw==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:49:27.432363+00
r2ZeZmWEGBfvmV0Yufpb58W4a4568-vsS-On4f_79zk=	{"csrf": "5LYnvdrEv8VRVYszUEFu0FOV9-kgKHi9d4whxESkYVS2zh5kfP9XKQ2RqKn773ol3aMVs9V8MtxxRYQStKLciw==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:49:27.595212+00
gAVr9Pl8eY6wizGpO4PQyY5v9FBN5_9c59YHjyEkXc8=	{"csrf": "tbRT4LhQjK1lohto1Q_xB_Jq_sx2y-f-P95GxLf9Ihvzj376WFww4ToOPyQb8dkSLxlvOOsFtyakTberAK-54A==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:49:27.716438+00
l8_11-W0-rjPBmh8V66egwTCJeD3Nk0s_-clbtBhBTU=	{"csrf": "xcy4v9i-m3IM8GmEZaAi9ltURIyECMYORc6yTes0EawXaY80FUVhdo4rIh_iP5plv77yuQn_D_O0rJ7UDVmQjA==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:49:29.689098+00
8GBT4fUEMtVtPEAKv19yrdKkFaNudbEZ1SA_l9d91cU=	{"csrf": "W6DLcetvegvz9yehb02x7y1AJLG29yEQsuIqCxfFo0Go7ZbjUeWs94tX1HjPq9MYyy888POvUmRudVvkxBySdw==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:49:29.73731+00
sUzr9gNq9dVxOtSIEHpaI5iBm50fERRCLcRP9Lhf6S8=	{"csrf": "IUY1DIk_HtNoH5F4SsN6LfFUMc3hn15jHYxRIiYeGM_h8An-7dejxVu3h7YF0xUQJrhuyH0iwRxs9FHusUUkTQ==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:49:29.809158+00
nLKYNE6iwHk4P6LjnPWgduJ0263INcAtV0kKbkph_Vo=	{"csrf": "9ZxFXmniEBIGM-38w8HZwjaED-2qOYmSzgEUxuBO9xDBhkT2kDZUWeiMuxXu1mX4CQ_D9GknA54dfXla4cqzzg==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:49:29.819476+00
aYgFTg6EB2qz3Zd0LUStb7PRwN7kAFfTl2GOpv1LCzI=	{"csrf": "5XGOeN7-HtpX6408WyfMsq4LgxA2ZMjhkASlmpbWCTPcJjA4o2sL336jYraVEeuiMYY-7c_V9muFv79KEt5Ofw==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:49:29.836262+00
dssgmxHBzSmULGhE6pmWNK0yPUheRT8SPL1SoWr-Gj8=	{"csrf": "Z7Nl1pKSdvPyAKGzMMYDPBVMzALPKsfpM_kkHKDzybD2EDxgif97MPV0szQLmv9JgVs3sA2HifOtY5VurUCVbA==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:49:30.061036+00
AkS8MFVIfcvHnt6wRIpd3vlcz3CN75cMouyB_AOeyNY=	{"csrf": "etyU5twU-lkk86LcOX3L_f8rkpKE6yW8hjqOatt5Jz56MAQkw4kAhw7TtwaXE5bccW-OSsDZX4zACs36yqQ6fg==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:49:30.077409+00
SEqhWWlf9dmwLQgrDbHrn-zjw4X0qJJloTU45avjWfk=	{"csrf": "Y8Cc6yl0Zn8gG2uAmxN416nff5gnSJaE0O2IDXs1wHpc7dEnVhHNyyafIupUUKsdE2xxyCL8BCAJYxayHKWlbg==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:49:30.078609+00
VSKwI41g_0Th2FmGp6smy2QXt3PEXVXi21boFsmdGUc=	{"csrf": "rcUHwWtrLw3pvQ_CbFUf01kLqlRD2HecpKkxjX6s1pT9LK6bzeD96HCdelMGdUGr0458PkIe3ltaFAaX3ZeQuA==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:49:30.123462+00
NHjnMnuB1zA3p57LeJSbHH46UjqrHG_r38zeaJqK5zI=	{"csrf": "w1BO7bosi3zw3r7IXCHBlscT6czAmSvtoHikim4_RppKw51Gh6mFYW-Xr9IKTH89QAxZ0I0pjR0-syfVdvdyDA==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:49:30.507659+00
jNLccJjmHWuedtMj66EGx5MBjJK7qvA8Vxm9-aP0ZiY=	{"csrf": "E2Ctxgj5GiNkit3k26iON3r0_yL873uYXeyCVtpq4eNg3iVzW8OfSN2RjM8YzXTym4maD1LlNfKgusS0kY-rVA==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:49:30.660394+00
OkF4jr8EcmkVEvMnMVZni8arelTV6FMMcYeLzeDYz8Y=	{"csrf": "jP6TOKt7l72Yy8ocID1u2UOUn0HgI37xbdY-y3w10PW661VjpS_VGVUbaGXSpuSm-llvKlsXahkQvC8NhIwtMQ==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:49:33.194288+00
H3MsEon57TSibMZS_x5EOUoCIfp2vnGkEPkltkW5Nq0=	{"csrf": "c3xvKPAmiHPwSpjoed_HQV83qRGJ_yefs3dJh2GrAjybiQVDOuhfs7-eYC-d8pgQsa7lvL74kIgsaSd42z-Q-w==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:49:33.216184+00
1pLr_Jhw-ydlwpsfswGwQ9ez_qwZ-8QnYLxidhXTwgU=	{"csrf": "wR9-iOtCD72Z5kRkm6wG_6gMNU4HHqHOt1-mmgpf9E9zSvsHDRZBwyx2KDErz8EPx3iWx9mZgD969xwyGbI27w==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:49:37.443326+00
4u8o5mVn9fKRY3rlEXAx53mY8qFo0NS58bEn-Z8KbtY=	{"csrf": "0xIFF_X3thCV5p1qi0WmQ2pYR_itR_rPP78VBh4QuiOAg8-cy_SPq71esan67-ayooI0HRzJFcSahqvOel9T4Q==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:49:37.829819+00
TSBIy7_AuQTvCNhh_PoeFIukhKAYkxp79jpd-XxGvr4=	{"csrf": "nMLIYQJMmByqYj4DGtgYlDOhszc7Q456FwPn3nmNG23fNfmPcwbCUy3JlxzREq0HTLxljvNBQnY7DG_-dZLm0g==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:49:48.722564+00
CiJRqc0LWCWoQxE7j9WCH4eYCat4lHdJdV6Dje_cN_o=	{"csrf": "iFOotxwYy2iQ5Jy3foGBhjBCuvXmsVO2tY2STXvdibqubx_5_IQHnDkH7gigbPyXUnLRh_eeWfBbB_WVjI8f0w==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:49:48.893465+00
QaeiROyTFim0BoZrTif01UEdrBRKrg3ohsjBPFFqyh4=	{"csrf": "q0_AARPDd7LfN5CdcJ-4XA7ExkNOHatZdZ61HjGzyY84WQ1LQoFft7q3HoCBM6pnDt7IV97xifEr2kSyZjS1lA==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:49:48.916641+00
b9ZgYb6Aog-K2qrENRk_Dv1k7fT-ybvu1CbAu_un4BQ=	{"csrf": "F2DGh5HjGVneGcsYfrPKk33nUJfnoYq8oKmQIW3JgVH-KC9A6KIbP2RjA0KCtb1iB2TxwAwmoDxDhBmaiOpyLg==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:49:49.164813+00
7M-6k7w6NlYODGEpLYDQFhMrTJZudnsODOEQJoU4q5Y=	{"csrf": "n3w6oVueT8RibwS11ZXTJV6ZHmwkcW200dH-M1xPHVbKfCkFXHPu8sKieAMKe0LdsJkmrpO0oLi2oWl5-wtwFQ==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:49:50.506625+00
JWV2L05sTHCRKMofk8zbRMXjzUL1sYfDsaa4LJBOls8=	{"csrf": "Wzz5xIBUEOgeV8zdr7X_b0Nl5eACp93gFcda4_5RLfVW8LPjdN7OFE2_LcEoSWplOVgO_hWCFGfkWaybybSpNg==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:49:50.516781+00
InYWQYUYr2TRiOcUyOkfVXtWUgRpSChAi2O-kn3MlNU=	{"csrf": "i-Nso34H10DVVLHV8OeCJ_NJw3JRif1wDlbafA0leQ1L89SVjETpt9phdN7zEEMlFPv1BZ2C6xh25GnQAlYs2w==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:49:50.623722+00
CnF9VEY-Z21ogTIayZyPkpkQ5S4hzeM1nABbIzy_HHg=	{"csrf": "huO3BZFAOCDUoGq9xJz4C7c6QNybvZqVG_tJYNN3xkRahe47QGa57LDAb5QRxF9Xn6A1KaEJNAxhKPqqi6kPkw==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:49:50.891918+00
8tbyNaFI-WD-mYPkCyxnJR7Bst6JRZjBEBoU6OrJhcg=	{"csrf": "v3Rv3T6DXN79eR2Eu4aT-guvwuaxdnHIdZfqqJTkNglhRgoUcsOWzmGNTpZ9WvjYJ6VWZmcsWuOkYN2dj0CIGA==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:49:56.011279+00
Qggb34Ceipu77HaEe0bqellqPXZJNsA_5-7p4IhS9mw=	{"csrf": "dNRADsvm_ILJ3q8ODa8klIdRlX7m6itFUQ-c0u7iJLuE5w_uyCfJL-5U0qavmxGBO7EBj19fTnHdgQzJyiTogw==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:49:57.111616+00
MkXOzw3lzsmU3fxARwgl0EOA5rr1NCS7XdrpJgqhwII=	{"csrf": "vkne1TEBQhMb6PEztfGnqxRix0T2bXY9WDpEaQ-uTOJSkGBOj-xUUixRAJFJWlMnCn-CTwCahbbRv4GqxafPig==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:55:32.517306+00
V3VhxVRiwbc1xa3xuNzWZOf2VKbA5ih8I-B94DsRdWI=	{"csrf": "2-qKtBsLSJXEoTojrcBSN8D9dByWRLutAdxQsPPBSuWiJEHU4rN3QUDqybd2IAr7RiIeI3U37wi9Pq1Xsw1I0A==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 20:56:30.51441+00
qnAZC7Hc1P-Ffhdk-m6likEalbV1CZOSmB4wHvAlBao=	{"csrf": "xf1sUH3lGwltquzw5E1TtAG4_vNBesyEjAR4vWUBW5_w3IRbsWgcYZfhHm4gME7oTNHMwVdtnncgPByjwfl97Q==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 21:10:15.62976+00
rUNA8eOYHGLUJoFnXMGFkaJlwCyXEyE18gdA1vvaGIg=	{"csrf": "GsT_kxnAmQ5HDbkGLn-Lewxw33-8OVr9b4rKR5IsmmMXrY1_0ITh6WCd_XEm8bPMxT9IL9dWif0QZxmODIBX-Q==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 21:13:07.831478+00
iGMAVL3ecE5yxvs8qS8uIPjlPwf9a6pFLdPUs0cdb-4=	{"csrf": "nCA-2tVvLXTLz1McNWrgtctmT4jV_IyLNAr5H6oOAkEQi5CWiGRUd6iuZgKIbn7vzPcZIyd33aDjJ17LnsOfdA==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 21:13:36.386914+00
9bZPLPeEKcdCl0lUgaMerQgUb_mRhGCOsx9tgBtyZnM=	{"csrf": "pWi7YXrylmGFB3zJ0GhkJhswCm_5yJm4PJyTuba9z0h-DJ8OuOhUvsvXVA84vqL0W9Xz3Kod1bIGAF8TbBHwIQ==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 21:15:01.194625+00
Kf5QR9Tiw5KXWWabZf-0E24Sn2tmLmgAmvDmFJnEN-I=	{"csrf": "ouyarcHU-uG-OOyDU20cPkuYy3KUFQSnwSjxQO3jfsHsjJe0UI3x1qY2tmN_wAPlUio_kGQgHR74D2lrv7fZaQ==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 21:20:45.137545+00
_FxR2Di5A9bF6PlMdwA3QwMTGqY3Zy4jyEO4Oz4n6DA=	{"csrf": "_YW7gfGky6qp60PuNqAYp72GPI-cuT3rE2ejorcHxX2Oa7K6yY7yk4k9k4fhKInpXEvDzPuWgU6Zpfh4EPkRPQ==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 21:20:58.367821+00
Uubj5lho12YNswjIfzMABOuT2ixdWonhWVId6DntFXU=	{"csrf": "draat_0fr21nyVRI6GRdWPpgdoU7eZOHaQ0KLtoM07X5OPg9ODV56LJHdvhRc1DfBf75B4Ze011GGpm4qRmvaA==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 21:21:07.976743+00
eQJARYFCa9EPed09Kso9F7a5tBKtzal0z0T196PHv1g=	{"csrf": "NXzBKIqvd1qvUnJ8pfJQAAP_9oKEMsSmiTe4kTVsGtbnjTSD7krsFRkQb9nxtgXBltucCxOFOmE5iyuw8MhERg==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 21:21:09.346908+00
WyMka_nmaXJFwI-uvsHgp_tGIfJDHAfYoAaRUd34um4=	{"csrf": "grd5PVwbSDL4NGE0nyzGg-TtPwmVQP3HvjenrKYlizOWHIovKQNRLQYhdcZVVZXKYOAQ4dWfIii8zBtQZW6Cjw==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 21:21:09.406963+00
5y-qEiZup5uaYdKU0PladgsL2oEDopnMHhlSKkZ5aCY=	{"csrf": "5BsiRRR0HkcAaziyoi7Th1myM6PgO2xu_rkIoNQiA0GE8z7WsA3yMGo1rviIclXd0zPL1-qFBlGIf3nNRKnMKg==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 21:21:09.415698+00
pL7aUQVrmA1iX573FZP7j5CsFxvOJGmNjhbS2cT6bDw=	{"csrf": "exHDkLNFv809MW0LB4BL0GH-Ysmyhk24uF_FguED87Z8GOATOXAVfik-FwbR3S8Ace9gz5XwEm5eUz1QbkrE0g==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 21:21:09.421622+00
CJX4rZC-YG9Q91uLlIEFyUHjH3uE74zgWm1WtP_Rr1g=	{"csrf": "iHKiGczCuKEALhr8ZGs1m-w4GsLEn3up841SSe0AzWJ4-n9JYszzYpa9TZDIgmY0XC9AO8xt2iGBt893qI9YAg==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 21:21:09.456152+00
KnXGLvvkZjIWxM1kptrpv2b-h30EizLkUvCROLgI40I=	{"csrf": "PGytpAPl_YHuN9Zdj8n6oKbpS9tTNavEddXpLEkdwnC8uhQCvQGEK9yDPxyz3jEKNpmzE7dRb4tl8c8bAXPQOA==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 21:21:09.496175+00
m4sB-EOVWD7pfHKOYwAVO_OQCDFK874jJrP9lz9nH3s=	{"csrf": "zuEWJ2X-orGuPoHDGwLa8LBNYLjSEVFLz2kg9jFgIvbuI-p6D_LOJ3NR5jh1JNP8TAXMac8Hngy8BQRpxCdzyQ==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 21:21:09.505728+00
7rd_-cxdkbuzsO_zbYog0MUHTn0bu4Jyewsf99DP994=	{"csrf": "vH0GOTfi8joNZHU2n3TpoMfV9ddtHTPHxeHTBAoyfzcotasCBj7IEJWx41W2LojUAIzzIl3gkf151oQG4YayEg==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 21:21:11.219111+00
zZa4mr-xg9WVUKL-LwjYvDiMQCwy7u9dpUtQeVZ7q8s=	{"csrf": "ZVwEilDDVFw_ZfihZrGnkgTQ7JK7YvEeJ41WCZ8q8HgHcLAIJPZbGx6aYFua7FnpjcySDd_fEXgs7iVGrHoMMw==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 21:21:11.30966+00
p1DzOo4olgij1fkNRlzRkKzGxYvEZf_dLf_BvbBnPyc=	{"csrf": "elEjkdfP-nZ1Hsyd_8G4jvoRhHVfQqsgwrY-GTW1hWXK5QMgvtDWgismkDv8jVGs_ftfNXnZop7aipm_xnZAOg==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 21:24:46.544054+00
e3jYKnotTU6T37xQ-KLS7ncPNlVi7gmFGgpzm9yhYTA=	{"csrf": "QnAniCY2e-0I8xBfh5o4aw1PgcHODt1l-mDHLn2zxX76eZLgkhn1qY4iGHKh84lqGbrHUm2oHXlIfi0x8fWAGw==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 21:24:47.729434+00
xcjRv_KCSIHohg13QuAJtQv19ieLZjF4QOLASxDhaOo=	{"csrf": "llxgyBRktf2jHxeelYSkz7W-zuOCkpGJMv8JN3XvjowV1BqTmnCWKklvmdrrxn72A6d38bbbf6w249XW0buwgQ==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 21:24:47.77493+00
Lis_PtSZaIBbu8g4OTsEOlfEMHQyLsA0et1SBYu_4ik=	{"csrf": "RWm34r5sxXB3GF9edBnElPtAHISd71ue6aExv-Yw6GrBRJGd_Hqdqjt6zzIkpyx339mnLGFvZEQ1KcXBKaE7ZA==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 21:24:47.781349+00
HsBeF1bcRWLVsY9UfLS1s9rkgSsSzcBEt3wJa4HagmE=	{"csrf": "qTfPrxFmduEedcdIYbFuFPieNoI7o-H_oL1a3jZzBAYbeEXks3rEvrOb38EwjnOFK8Fv_H-r06FGMYgg0WAMxg==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 21:24:47.782558+00
MzLJfUB_wRnmWeeB6iI6qQVG3O65Z-pvnPWiRDJYPjA=	{"csrf": "AqANBfSuVCmDcwnurmBKXFHQ3gyRGVesdUKyw30yXraGaUyq6H4GLzwH5QpJ7NkvPwIyaiCrOdSdnYO-IyNGqQ==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 21:24:47.827715+00
GJLZuNb0K9Xt-F935-pFON0swLgpDNf1DrlsWW-BzQA=	{"csrf": "vaUVHu64hRIK9bjWh7aahcWqRjyJo6SnapT12lb1B5lp20_vq1nOZkw8adSHLrD7PUtPkKdjC9s4U3rKMMoW5A==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 21:24:47.85573+00
tW194FQw7POhVzGXM4GF-Kp1woMEotESz1-Flpgf0q4=	{"csrf": "QPdWNle3YrudMuN_BZQ2sAVP4GbxWa5elIJ5vOwyGiTV5Uj5dhiit7YYI2xpDYewjC4t0wX8TrBk6ZsSyoNGLA==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 21:24:47.864464+00
oyKL0wJZD-A_xOtG7TBPCAPa5hqu7Q_lcobe7Jc3-Pg=	{"csrf": "58USAKy9yJvrdNf7nn1Pwabw-cX8nAwQqbNKpxAxutRq0wEtL3DMjAvwWfjMDbVge4VZQ8mVMzkrpDwlKSds7g==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 21:24:51.081166+00
vcsxmDPG4lNi9bUQnXDh7lJEhH54S4xo6jTOwSwy6lE=	{"csrf": "F-U2yrq1hlxSqkTGQ49d-gS4lLh6AJuCIInQK-0f_R41CWfk5JRsKGB1H_nfbkFxnMxR7aj59LP5JP9UT5wTwg==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 21:24:51.496355+00
kM0yeVrD-lkJDP6AK1yn9T2S4Gbr_fCrhh3f_nSCmYY=	{"csrf": "Z8ujcY_nNuWsgYHZY0Y2smcU1ma_CvKLdIzuWid7iBcckPNL8wUU10g9hGQpFaeK-Xc23JmvPNePWNg7bPBLJg==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 22:08:45.686327+00
xqcWDbMEM1YPm49I63nx-wrsmNIXZ4eBOVXiAK0Lclg=	{"csrf": "Zm2Axmrxo09KHrxy7Sx5K8u08g6p-0Eg9gQwqAK6G_LDqil8PzvgJdvc3TWhg6eaxJh15eBQsSVKPMnSSzPg6w==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 22:08:45.784795+00
p8seJnT83dtJnPsTzayvGTYl-11ZHnVpWNNuMGfYL1M=	{"csrf": "_GKSGclHIDjDKUk05VNi4imFtmsQW5XpuxQ7W6Ubg0XP2ZQBRkJ6BrRxdnWS74SC3eHU6z_sKPVPINyJQRLaiw==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 22:08:45.795525+00
uYLW4hAY-kYY6_J3gG0_ur5DJUyqzpsKEGiG0DwHfe0=	{"csrf": "A8rExPxGX9kb_pnWz2QYcWhmz9X3Lka8pwlLUGBKxe0X0G5cf8w-qXMzPhbw5jS-jpLiE9ydGmNix2-rvoQ-Gg==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 22:08:45.80336+00
EEALuZVcqkyFNeB87okcGcAdDfEn3l3qaV-leRVgtGw=	{"csrf": "5J61hA8Y--1SQZsaqpE_jcN-ttOEkU5vwvT9kYpy3QwMBeaQ84mM3jtObpdyQ9qiq_QufrHIqKeAd0OFiytyJw==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 22:08:45.843552+00
_SmZFpuViUXWcgg7V2KQ5iywYhQBmzRCM1ssi03CsZI=	{"csrf": "zYDt2pLe_oReAysXxeIEQvY47Eom40zRpXaNJaRkuhawbrrsDTd1Kdd2irdU9jFg2JqJf_ZkGJS6gmHFk5el2w==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 22:08:45.872978+00
0ybKIv7LKggTaJZ7xhqkgXMzSmO2fzktGmokJtQBuxg=	{"csrf": "t4FDKAFYuk9pd5JpOpj-O7_VXSmohUUa3_pOCmg6pLELMJoTUv08aFPwlIPNOy8qbEA6m75Mb_Jxk2-7MvEhgg==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 22:08:45.873831+00
mRzaBFMZy2PPB2nBGv2Iz1KECv7qrEW2TWm4bVLFlao=	{"csrf": "3RmrxB40ForklorAd-0pZcTY1e4wkJ_hulM-4n90MepF6V35_nqzdldu18qYSAWYynX4jCCPLwPjKY032EpnWA==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 22:08:47.176657+00
QWouXrAT3Zum2XmhHJEbqJ4xU5qeWV-1QlznpJW6BPc=	{"csrf": "5VIgNgnymm8tRgOD6MVocr5hEzi1VavVat-NAl4uuxz3Kn2Th_Np4-TH1l0J10O5mrF8VgKL-vRJ3GXOBOEy5Q==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 22:08:48.919212+00
pI9Z-YlkO-BzjaABVMFVNrnAHPpSFKpQXjGIKth7T4Y=	{"csrf": "ckh2Sp6AcX0JvSmQgcwYhePk2qQNofGLmiIE3D4GAWsTxsOr-rByV3ym4xLJC_fTL81w9KKnRruUyk2EysbcaQ==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 22:08:49.060316+00
Q_ix4m7tZsuVuOT5ygnnNJQ1-WJEThQ442sYS5V5MUM=	{"csrf": "pxkesQ-KZbzfZx_nSRyF8bt_zFfqq7bCVRnbhrOELh2JoOVpsGrSUvbmVhDGwyPhzWtZ2D82GYSUsvoOc3JCGA==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 22:22:23.892187+00
onkCeFEYzU9iacYJfSzD6rLOvGMr8XezxK2kQYQkOdY=	{"csrf": "olnP5Ni0vbUizRlHZ817I_EYjpX2W9ODA2rzhkRzle5q-p2w0mAFW2ohnrvvkrEAqH9_sG6aGiiEBaiJTbzTgQ==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 22:24:53.371064+00
g-DqSr-Oh08sygiuNt0cKkME51FgWLt9uO-i4BY2DkM=	{"csrf": "09lu2JRGVP-D46TrqrcewGoCJ2PYJDEk192XPHBkCxMuV3yNhJabQaPNjxjY-4ckg0yOYl4p96yDM0o1BnG2Lw==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 22:24:53.742673+00
c9-8gM9PB4mj2PTHnO-ITv_JzB11vfoQSNsiREsx9OY=	{"csrf": "jLZ3LuAXVQyeTRHb0DYnRt5KBTElXYcc0aYdBLktcG4IpZuz6TKWn1vXK-mQgTuXSsPJA2g4QM2jUL53pr3lLg==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 22:24:53.791846+00
pn88oT8OFa6FULDfjl5O-Dz2jwytWl8h_8zCpfOy31w=	{"csrf": "Ix5f6UTTr53Pw-hzD-EBuPTp3PsHSSjOt7WwIUUwzJxCc21aBNPz-YLpogYvANVBHeAEYmRZkE_vrLv_8NYrWA==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 22:24:53.817307+00
1tJNKVxtsBvd2atcumyeKDlt5DXCLfIEhSQ-uCZ2l1w=	{"csrf": "R8V1fktNkoaBxuJq054q2jW_q9j9qyAFj0SUWrQfPsGue3axeMIDOH1OCJVvusiDl9YtE6MyfUnbgedsYDOR_w==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 22:24:53.832694+00
Rk7nTELyzGRHoheyQ5xHsD1yZ4ybslq-rm46QBEpmfQ=	{"csrf": "B5Woxbto6rV-rsnIupRPjNlbr_o556QJDfmSVYn6E5muN-7trYaMfrUCH7S0A0IFYMhZKWx6AH7O3bPQEISJtA==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 22:24:53.874082+00
smlSPacVOkQeo0_6PUJKmcEjWexHLAO5s7bSkNGbRU4=	{"csrf": "qHWdD2aaVxd_2rjUWEpn4qQia6qmVJfvrPb-DkUxFjAWROgXfEGkfLFkJ6HH77ZvhwtamvWhMvGDOse4ap-N3w==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 22:24:53.918857+00
I6TK_4rSG1GzhqqJIEaSloyrdl0fX_akYEiTQXGrMAI=	{"csrf": "HCJ-1YckHD2cYh4U2r9iDmp7uGL6tPxDKqz1vPOCMopSpRhc0XVS5vSKiQalaRkTdLofO24eEOL3d3miTe22RA==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 22:24:53.924294+00
1TDcozjz0TSkpufI8tLqjRK9RS89fURvyqWjN7Ag9c0=	{"csrf": "SwwTTfDy4sXUIgaUqb_8M87Ggv4cQZj7KTkRSPDSCpmiif5n7HynTOmuv5ACV9F-c0w9-AWHzX74mQeAR9N36g==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 22:24:57.147117+00
O3N68ATmY8kUFP8fvZtfXcTv2kYlmf3tmxPswgjvsdg=	{"csrf": "9bP8vybP7tIs7Pj80rpk7WwT125mKLdfOTpDJExyx84ztjE2MXFUpFKafTsi24KThnTve5KJoAtR4NwEOxFa8g==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 22:24:57.227332+00
WGM6E0M1pBY8H08hN5Gitd7lmBbQ9i1yEQTn6zsne5g=	{"csrf": "tZ_JpINnmbchENbG9KYJxrrte4kntsS5SKRgjnlqXB5TSoIIpOm09uX2k5X5mpfjTUBRXC2_xmEADBI67dz8vQ==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 22:31:20.903779+00
ZjwzyIB7-yEHBaHVvbXdV_GfgDpE5aJMPJ9TX0Chv0A=	{"csrf": "Jcw6tgW6b9PeqOSVpKdzkXHh1T-TDMmX20WVZBqS7dMu1IPHSr-ln5NNu4CXeS1e-dXuqC1hbT8YWcXDT4yp9Q==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 22:31:28.884387+00
W9Q4vlI_UatzFEdw5twoXBkCl_iL0UhrC1aGjU78hSA=	{"csrf": "y0lam4gvoPZ1QUParZHYp_0guyKL8mk593CwDbC8SXhdLrxNK6UbRf2VGUs5CnVEw89e8_xD5RMy-nrPuSY_dA==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 22:31:28.951478+00
djhoxN9kqbjWYbFSZTHkXF9kz2sPm_8OQpb_a3tmjLA=	{"csrf": "sgZJEX4DcEoxa8kS7LDQiAkDaR9nX3j9Sqcp6CkAcSDQvba6cktNDIxtyxeGf-Y5qcE3GJuXoKMTBSsdAAjNJg==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 22:31:28.966795+00
T_m8TqjcdTFI7k7OztpXBnjXcjXOF7cLQUsC4f9a3us=	{"csrf": "FO_UXX7SiosLBUy3k6joHNpn455sYbsuW7uKr-6ExZT92pNQH7j2cuYaC_orf9VBcSt4ZO4YtT-VG5n0EDKMug==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 22:31:28.967242+00
EIeFr1ruafnqwVzxc8dYjuhoaNP8SxxOaakLxmKQg3c=	{"csrf": "mF8u2RBkDgt3KBf6qaH2PbxxpzhByJJMxbpOdxvEv7RWdiJksl97oO06OfxapIWxxKXZLf2oVCE13VSHJa5TJg==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 22:31:29.06289+00
fiYfK7FV8qLTaXm6gmTGXoGqGJQ23_QMO0MkyYK5ghU=	{"csrf": "JcmY_pudt8IVHAACbpYbeMbZJz-ON4n2tmp0gjKVDzXzh-D8gH2Fb0UpLLPg1M0naHkjJheMZ2ms4hWubCtxjg==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 22:31:29.094395+00
YRCwVqGZbEqv4tPxnWUBcTEnJtYC1QzyQ3dd2E9PrLU=	{"csrf": "hD0zjgDBTpZO-LVC24v0wE48DO5WY0NBUZ_c8gYCf4Vdt2nKdg1S1rc_OX9FTcFOujXs8pC_1F1gy8N8AbGhiA==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 22:31:29.117397+00
hLNnnqfHjFGCyFTMLXf_m_hvTgoYyXqh9s_X-A54jPU=	{"csrf": "VrEq-tA0VffsVWS2zPMfnMXNJ0V0DtfjUeLxa4h0dDgd3TOAeaWvbGlbOn-36zXZ80tBzMHlnQY0j2L1H72j7g==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 22:31:30.708029+00
PZIY0AGPDc-P1YcacIjNeO-wBYFrPoo1Vvrzdw3rujc=	{"csrf": "xGoC0I_Ux1iWNKmyYGXl8Wue7yu9752VFGoviwCdbBLgTiuWieZ3gnoJ1L9yJf822LoCzgxD_Y6kygj6H8Nu3w==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-07-10 22:31:30.807758+00
-XOc91iuCmzi3ruEQ2RSfJ9wbGKJD8ilQ261xvQZaUw=	{"csrf": "MxriJ0FK-BR9eWALNhqxtpevxguyLIgJtAy-2bzdx9zZNCwNscm1L9KR-6zji1rHW_azNXXYqGwtzjq9PpASxQ==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-10-09 21:46:58.060402+00
bDN32adgNXV0ZoIL1X3IljapPWEzCqhVDEq4paw09dM=	{"csrf": "n9_aCjtPqQ5D5n3U1LTA7C2_wr9ULDgsprcvF9BvFbaWSxhcJbOywol7euGT05Pq28zadY9xslh4WRGnjyTGuw==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-10-09 21:47:58.133459+00
cuCkbbbLXFvqp0T154MACTlLO7Ubmf6IQ6Gx8y_AgQM=	{"csrf": "5PLGUMgfVXYMW6s-gL-Al_EzE1u2qoadwpwBOw4jhmmMfkdfug7UI-n6FMAoi4m1VEvCGSApxtVG26ETYyfBUQ==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-10-09 21:48:58.179579+00
yjC8WqBuA4TMfrVcXYOcuKlzFDpmzrqtNvvmqTie0gc=	{"csrf": "vmQZlO1sfEEDmfTTggfs9mipEFzrjkk_cdpQXLI7tAObUzPZBsJdzU8cQYtDEvBdt8lZos8UYgAwuLRzNXDsNg==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-10-09 21:49:58.221729+00
Ka3nnOsnsLDj2DD_zcKO6h1hv1ChtT5EYZYJdoGGtzg=	{"csrf": "s7nzcx7-wYTvpgVGVj_fzfckLHcuDQobQqc7gvLig7YjoWOnDhEURUluVBZVNdCGDRnyE7FId4p8dcHfTIGYRA==", "theme": "", "language": "", "oauth2_state": "", "flash_message": "", "last_force_refresh": "", "flash_error_message": "", "oauth2_code_verifier": "", "pocket_request_token": "", "webauthn_session_data": {}}	2025-10-09 21:50:58.270443+00
\.


--
-- Data for Name: user_sessions; Type: TABLE DATA; Schema: public; Owner: miniflux_user
--

COPY public.user_sessions (id, user_id, token, created_at, user_agent, ip) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: miniflux_user
--

COPY public.users (id, username, password, is_admin, language, timezone, theme, last_login_at, entry_direction, keyboard_shortcuts, entries_per_page, show_reading_time, entry_swipe, stylesheet, google_id, openid_connect_id, display_mode, entry_order, default_reading_speed, cjk_reading_speed, default_home_page, categories_sorting_order, gesture_nav, mark_read_on_view, media_playback_rate, block_filter_entry_rules, keep_filter_entry_rules, mark_read_on_media_player_completion, custom_js, external_font_hosts, always_open_external_links) FROM stdin;
2	alice	$2a$10$yDniENeGz1foJ3BZXv42femw/CGbSyuLSQIsYbrYOHtHWmpM0srku	f	en_US	UTC	light_serif	\N	asc	t	100	t	t				standalone	published_at	265	500	unread	unread_count	tap	t	1			f			f
3	bob	$2a$10$pgpvYwri9f9GSp8O1JtU8ue8q9fqoiIByoyNOuDdEEqJ16h0jL58y	f	en_US	UTC	light_serif	\N	asc	t	100	t	t				standalone	published_at	265	500	unread	unread_count	tap	t	1			f			f
4	charlie	$2a$10$RMokmwTDnc/FTxb.7B7lMuaI1Pm6H7Q6s6yP7cZUeKqMeKEU8zGvq	f	en_US	UTC	light_serif	\N	asc	t	100	t	t				standalone	published_at	265	500	unread	unread_count	tap	t	1			f			f
5	diana	$2a$10$.ddJxK/DmNdpXYqbf3JVwuqSbBdMd2GJfsDF53abZYwXARwNjfvne	f	en_US	UTC	light_serif	\N	asc	t	100	t	t				standalone	published_at	265	500	unread	unread_count	tap	t	1			f			f
6	eve	$2a$10$I4jZetIJ8UjToKVc53PDXOMJcCMykIJZug3o99T.3JpkC7tETMdOi	f	en_US	UTC	light_serif	\N	asc	t	100	t	t				standalone	published_at	265	500	unread	unread_count	tap	t	1			f			f
7	frank	$2a$10$UYFGqIeLWVKGWVsAhaNPleO7SO43FB3uHwjvBA5eJWwDrj/wRVTcy	f	en_US	UTC	light_serif	\N	asc	t	100	t	t				standalone	published_at	265	500	unread	unread_count	tap	t	1			f			f
8	grace	$2a$10$4NOKf059gIWS8i0XcKMnMuveU6/Ob9ri5ovxn7lUjfMytlCEwbgqq	f	en_US	UTC	light_serif	\N	asc	t	100	t	t				standalone	published_at	265	500	unread	unread_count	tap	t	1			f			f
9	demo	$2a$10$pwzzSUC8/3UFfmiXObw7ne6jPhdbW7r2c43Qz0iCK4KaycYrr3cSS	f	en_US	UTC	light_serif	\N	asc	t	100	t	t				standalone	published_at	265	500	unread	unread_count	tap	t	1			f			f
10	user1	$2a$10$UoRWN5fir3VeVoGSiq8Dku92NSggekx297buL2GDbQaqIvf9yFUkW	f	en_US	UTC	light_serif	\N	asc	t	100	t	t				standalone	published_at	265	500	unread	unread_count	tap	t	1			f			f
11	alex.chen	$2a$10$zMHYpk0wvTUoR.aCvwMxReP0UgBp15TdWpAjf64huyCCapFv0C/Ya	f	en_US	UTC	light_serif	\N	asc	t	100	t	t				standalone	published_at	265	500	unread	unread_count	tap	t	1			f			f
12	blake.sullivan	$2a$10$3RW3n7SSpgDJEFUQs9/w2OyDAVZeHzuVXFPGbn1KD1uSXzlWntQI.	f	en_US	UTC	light_serif	\N	asc	t	100	t	t				standalone	published_at	265	500	unread	unread_count	tap	t	1			f			f
1	admin	$2a$10$0SKn0M.0CITOeRYkgPaY3ePGgxb338/fc3VMlAopvfhyn71woRuMq	t	en_US	UTC	light_serif	2025-10-09 21:47:11.902971+00	asc	t	100	t	t				standalone	published_at	265	500	unread	unread_count	tap	t	1			f			f
13	mallory	$2a$10$WKa4b99ehJJVVPuU95OzsuXBFpCRZEOwvss6idmqqb4/0u9i1fFUG	f	en_US	UTC	light_serif	\N	asc	t	100	t	t				standalone	published_at	265	500	unread	unread_count	tap	t	1			f			f
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

SELECT pg_catalog.setval('public.categories_id_seq', 13, true);


--
-- Name: enclosures_id_seq; Type: SEQUENCE SET; Schema: public; Owner: miniflux_user
--

SELECT pg_catalog.setval('public.enclosures_id_seq', 1, false);


--
-- Name: entries_id_seq; Type: SEQUENCE SET; Schema: public; Owner: miniflux_user
--

SELECT pg_catalog.setval('public.entries_id_seq', 1, false);


--
-- Name: feeds_id_seq; Type: SEQUENCE SET; Schema: public; Owner: miniflux_user
--

SELECT pg_catalog.setval('public.feeds_id_seq', 1, false);


--
-- Name: icons_id_seq; Type: SEQUENCE SET; Schema: public; Owner: miniflux_user
--

SELECT pg_catalog.setval('public.icons_id_seq', 1, false);


--
-- Name: sessions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: miniflux_user
--

SELECT pg_catalog.setval('public.sessions_id_seq', 1, false);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: miniflux_user
--

SELECT pg_catalog.setval('public.users_id_seq', 13, true);


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

\unrestrict AQCEwbUFGqSywalaaAWkH5LfcddeA0c5hfmkGMRaovU5X5eXzCkcuON0fF4bgyC

