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

type GiteaRepository* = object
  id*: int
  name*: string
  owner*: string
  `full_name`*: string

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
  repository*: GiteaRepository

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
