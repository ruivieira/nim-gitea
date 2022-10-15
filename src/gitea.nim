import httpclient
import options
import jsony

const CODEBERG_HOST = "https://codeberg.org/api/v1"

type Gitea = object
  token*: string
  client*: HttpClient
  host*: string
  owner*: string

type GiteaUser* = object
  id*: int
  login*: string
  `full_name`*: string
  email*: string
  `avatar_url`*: string
  language*: string
  `is_admin`*: bool
  `last_login`*: string
  created*: string
  restricted*: bool
  active*: bool
  `prohibit_login`*: bool
  location*: string
  website*: string
  description*: string
  visibility*: string
  `followers_count`*: int
  `following_count`*: int
  `starred_repos_count`*: int
  username*: string

type GiteaLabel* = object
  id*: int
  name*: string
  color*: string
  description*: string
  url*: string

type GiteaSimpleRepository* = object
  id*: int
  name*: string
  owner*: string
  `full_name`*: string

type GiteaExternalWiki* = object
  external_wiki_url*: string

type GiteaExternalTracker* = object
  external_tracker_format*: string
  external_tracker_style*: string
  external_tracker_url*: string

type GiteaInternalTracker* = object
  allow_only_contributors_to_track_time*: bool
  enable_issue_dependencies*: bool
  enable_time_tracker*: bool

type GiteaPermission* = object
  admin*: bool
  pull*: bool
  push*: bool

type GiteaRepository* = object
  `allow_merge_commits*`: bool
  `allow_rebase*`: bool
  `allow_rebase_explicit*`: bool
  `allow_squash_merge*`: bool
  archived*: bool
  avatar_url*: string
  clone_url*: string
  created_at*: string
  default_branch*: string
  default_merge_style*: string
  description*: string
  empty*: bool
  external_tracker*: GiteaExternalTracker
  external_wiki*: GiteaExternalWiki
  fork*: bool
  forks_count*: int
  full_name*: string
  has_issues*: bool
  has_projects*: bool
  has_pull_requests*: bool
  has_wiki*: bool
  html_url*: string
  id*: int
  ignore_whitespace_conflicts*: bool
  internal*: bool
  internal_tracker*: GiteaInternalTracker
  mirror*: bool
  mirror_interval*: string
  name*: string
  open_issues_count*: int
  open_pr_counter*: int
  original_url*: string
  owner*: GiteaUser
  # parent	{...}
  permissions*: GiteaPermission
  private*: bool
  release_counter*: int
  size*: int
  ssh_url*: string
  stars_count*: int
  `template`*: bool
  updated_at*: string
  watchers_count*: int
  website*: string

type GiteaIssue* = object
  id*: int
  url*: string
  `html_url`*: string
  number*: int
  user*: GiteaUser
  `original_author`*: string
  `original_author_id`*: int
  title*: string
  body*: string
  `ref`*: string
  labels*: seq[GiteaLabel]
  milestone*: string
  assignee*: Option[GiteaUser]
  assignees*: Option[seq[GiteaUser]]
  state*: string
  `is_locked`*: bool
  comments*: int
  `created_at`*: string
  `updated_at`*: string
  `closed_at`*: string
  `due_date`*: string
  `pull_request`*: string
  repository*: GiteaSimpleRepository

type GiteaCreateIssue* = object
  assignees*: Option[seq[GiteaUser]]
  body*: Option[string]
  closed*: bool
  `due_date`*: Option[string]
  labels*: Option[seq[GiteaLabel]]
  milestone*: Option[int]
  `ref`*: Option[string]
  title*: string

proc camel2snake*(s: string): string =
  ## CanBeFun => can_be_fun
  ## https://forum.nim-lang.org/t/1701
  result = newStringOfCap(s.len)
  for i in 0..<len(s):
    if s[i] in {'A'..'Z'}:
      if i > 0:
        result.add('_')
      result.add(chr(ord(s[i]) + (ord('a') - ord('A'))))
    else:
      result.add(s[i])

template dumpKey(s: var string, v: string) =
  const v2 = v.camel2snake().toJson() & ":"
  s.add v2

proc dumpHook*(s: var string, v: GiteaCreateIssue) =
  s.add '{'
  var i = 0
  when compiles(for k, e in v.pairs: discard):
    # Tables and table like objects.
    for k, e in v.pairs:
      if i > 0:
        s.add ','
      s.dumpHook(k)
      s.add ':'
      s.dumpHook(e)
      inc i
  else:
    # Normal objects.
    for k, e in v.fieldPairs:
      when compiles(e.isSome):
        if e.isSome:
          if i > 0:
            s.add ','
          s.dumpKey(k)
          s.dumpHook(e)
          inc i
      else:
        if i > 0:
          s.add ','
        s.dumpKey(k)
        s.dumpHook(e)
        inc i
  s.add '}'


proc newGitea*(token: string, owner: string): Gitea =
  return Gitea(token: token, client: newHttpClient(), host: CODEBERG_HOST, owner: owner)

proc newGitea*(token: string, owner: string, host: string): Gitea =
  return Gitea(token: token, client: newHttpClient(), host: host, owner: owner)

proc buildGETRequest(gitea: Gitea, url: string): Response =
  let headers = newHttpHeaders()
  headers["Authorization"] = "token " & gitea.token
  headers["Accept"] = "application/json"
  let response = request(gitea.client, url, HttpMethod.HttpGet, "", headers)
  return response

proc buildPOSTRequest(gitea: Gitea, url: string, body: string): Response =
  let headers = newHttpHeaders()
  headers["Authorization"] = "token " & gitea.token
  headers["Accept"] = "application/json"
  headers["Content-Type"] = "application/json"
  return request(gitea.client, url, HttpMethod.HttpPost, body, headers)


proc getAll[T](gitea: Gitea, url: string): seq[T] =
  var results = newSeq[T]()
  let response = buildGETRequest(gitea, url)
  let json = response.body.fromJSON(seq[T])
  for item in json:
    results.add(item)
  return results

proc createIssue*(gitea: Gitea, issue: GiteaCreateIssue,
    repo: string): Response =
  let body = toJson(issue)
  echo body
  let url = gitea.host & "/repos/" & gitea.owner & "/" & repo & "/issues"
  return buildPOSTRequest(gitea, url, body)

proc getAllIssues*(gitea: Gitea, state: string): seq[GiteaIssue] =
  let limit = 200
  let url = gitea.host & "/repos/issues/search?owner=" & gitea.owner &
          "&limit=" & $limit
  let issues = getAll[GiteaIssue](gitea, url)
  return issues

proc getUserRepos*(gitea: Gitea): seq[GiteaRepository] =
  let url = gitea.host & "/user/repos"
  let repos = getAll[GiteaRepository](gitea, url)
  return repos
