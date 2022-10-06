import httpclient
import json
import options

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

proc getAll[T](gitea: Gitea, url: string): seq[T] =
    var results = newSeq[T]()
    let response = buildGETRequest(gitea, url)
    let json = parseJson(response.body)
    for item in json:
        results.add(to(item, T))
    return results

proc getAllIssues*(gitea: Gitea, state: string): seq[GiteaIssue] =
    let limit = 200
    let url = gitea.host & "/repos/issues/search?owner=" & gitea.owner &
            "&limit=" & $limit
    let issues = getAll[GiteaIssue](gitea, url)
    return issues