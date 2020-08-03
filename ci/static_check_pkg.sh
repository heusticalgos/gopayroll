#!/bin/sh

# ------------------------
#  Dependencies
# ------------------------
# jq := apt-get -y install jq

set -e

# ------------------------
#  Environment Variables
# ------------------------
# GITHUB_EVENT_PATH := path to Github workflow event.json file
# GITHUB_TOKEN := Github token required to make pull request comments

# ------------------------
#  Arguments
# ------------------------
CMD=$1
FLAGS=$2
IGNORE_DEFER_ERR=${3:-false}
REPORT_COMMENT=${4:-true}

COMMENT=""
SUCCESS=0

# ------------------------
#  Functions
# ------------------------
# report_pull_request_comment is send ${comment} to pull request.
# this function use ${GITHUB_TOKEN}, ${COMMENT} and ${GITHUB_EVENT_PATH}
report_pull_request_comment() {
    if [ -z "$GITHUB_EVENT_PATH" ] || [ -z "$GITHUB_TOKEN" ]; then
        echo "Unable to report pull request comment due to missing GITHUB_EVENT_PATH or GITHUB_TOKEN"
        echo "Comment: ${COMMENT}"
        return
    fi
    PAYLOAD=$(echo '{}' | jq --arg body "${COMMENT}" '.body = $body')
    COMMENTS_URL=$(cat ${GITHUB_EVENT_PATH} | jq -r .pull_request.comments_url)
    curl -s -S -H "Authorization: token ${GITHUB_TOKEN}" --header "Content-Type: application/json" --data "${PAYLOAD}" "${COMMENTS_URL}" > /dev/null
}

# mod_download is getting go modules using go.mod.
mod_download() {
    if [ ! -e go.mod ]; then go mod init; fi
    go mod download
    if [ $? -ne 0 ]; then exit 1; fi
}

# check_errcheck is excute "errcheck" and generate ${COMMENT} and ${SUCCESS}
check_errcheck() {
    echo 'run errcheck checks'
    go get -u github.com/kisielk/errcheck && go mod tidy

    if [ "${IGNORE_DEFER_ERR}" = "true" ]; then
        IGNORE_COMMAND="| grep -v defer"
    fi

    set +e
    OUTPUT=$(sh -c "errcheck ${FLAGS} ./... ${IGNORE_COMMAND} $*" 2>&1)
    test -z "${OUTPUT}"
    SUCCESS=$?

    set -e
    if [ ${SUCCESS} -eq 0 ]; then
        echo '...passed'
        return
    fi

    echo "...failed ${SUCCESS}"
    if [ "${REPORT_COMMENT}" = "true" ]; then
        COMMENT="## ⚠ errcheck Failed
\`\`\`
${OUTPUT}
\`\`\`
"
        report_pull_request_comment
    fi
}

# check_fmt is excute "go fmt" and generate ${COMMENT} and ${SUCCESS}
check_fmt() {
    echo 'run fmt checks'
    set +e
    UNFMT_FILES=$(sh -c "gofmt -l . $*" 2>&1)
    test -z "${UNFMT_FILES}"
    SUCCESS=$?

    set -e
    if [ ${SUCCESS} -eq 0 ]; then
        echo '...passed'
        return
    fi

    echo "...failed ${SUCCESS}"
    if [ "${REPORT_COMMENT}" = "true" ]; then
        FMT_OUTPUT=""
        for file in ${UNFMT_FILES}; do
            FILE_DIFF=$(gofmt -d -e "${file}" | sed -n '/@@.*/,//{/@@.*/d;p}')
            FMT_OUTPUT="${FMT_OUTPUT}
<details><summary><code>${file}</code></summary>

\`\`\`diff
${FILE_DIFF}
\`\`\`
</details>

"
        done
        COMMENT="## ⚠ gofmt Failed
${FMT_OUTPUT}
"
        report_pull_request_comment
    fi
}

# check_imports is excute go imports and generate ${COMMENT} and ${SUCCESS}
check_imports() {
    echo 'run import checks'
    go get -u golang.org/x/tools/cmd/goimports && go mod tidy

    set +e
    UNFMT_FILES=$(sh -c "goimports -l . $*" 2>&1)
    test -z "${UNFMT_FILES}"
    SUCCESS=$?

    set -e
    if [ ${SUCCESS} -eq 0 ]; then
        echo '...passed'
        return
    fi

    echo "...failed ${SUCCESS}"
    if [ "${REPORT_COMMENT}" = "true" ]; then
        FMT_OUTPUT=""
        for file in ${UNFMT_FILES}; do
            FILE_DIFF=$(goimports -d -e "${file}" | sed -n '/@@.*/,//{/@@.*/d;p}')
            FMT_OUTPUT="${FMT_OUTPUT}
<details><summary><code>${file}</code></summary>

\`\`\`diff
${FILE_DIFF}
\`\`\`
</details>

"
        done
        COMMENT="## ⚠ goimports Failed
${FMT_OUTPUT}
"
        report_pull_request_comment
    fi
}

# check_lint is excute golint and generate ${COMMENT} and ${SUCCESS}
check_lint() {
    echo 'run static lint checks'
    go get -u golang.org/x/lint/golint && go mod tidy

    set +e
    OUTPUT=$(sh -c "golint -set_exit_status ./... $*" 2>&1)
    SUCCESS=$?

    set -e
    if [ ${SUCCESS} -eq 0 ]; then
        echo '...passed'
        return
    fi

    echo "...failed ${SUCCESS}"
    if [ "${REPORT_COMMENT}" = "true" ]; then
        COMMENT="## ⚠ golint Failed
$(echo "${OUTPUT}" | awk 'END{print}')
<details><summary>Show Detail</summary>

\`\`\`
$(echo "${OUTPUT}" | sed -e '$d')
\`\`\`
</details>
"
        report_pull_request_comment
    fi
}

# check_sec is excute gosec and generate ${COMMENT} and ${SUCCESS}
check_sec() {
    echo 'run gosec checks'
    go get -u github.com/securego/gosec/cmd/gosec && go mod tidy

    set +e
    gosec -out result.txt ${FLAGS} ./...
    SUCCESS=$?

    set -e
    if [ ${SUCCESS} -eq 0 ]; then
        rm result.txt
        echo '...passed'
        return
    fi

    echo "...failed ${SUCCESS}"
    if [ "${REPORT_COMMENT}" = "true" ]; then
        COMMENT="## ⚠ gosec Failed
\`\`\`
$(tail -n 6 result.txt)
\`\`\`
<details><summary>Show Detail</summary>

\`\`\`
$(cat result.txt)
\`\`\`
[Code Reference](https://github.com/securego/gosec#available-rules)

</details>
"
        report_pull_request_comment
    fi
    rm result.txt
}

# check_shadow is excute "go vet -vettool=/go/bin/shadow" and generate ${COMMENT} and ${SUCCESS}
check_shadow() {
    echo 'run shadow checks'
    go get -u golang.org/x/tools/go/analysis/passes/shadow/cmd/shadow && go mod tidy

    set +e
    OUTPUT=$(sh -c "go vet -vettool=/go/bin/shadow ${FLAGS} ./... $*" 2>&1)
    SUCCESS=$?

    set -e
    if [ ${SUCCESS} -eq 0 ]; then
        echo '...passed'
        return
    fi

    echo "...failed ${SUCCESS}"
    if [ "${REPORT_COMMENT}" = "true" ]; then
        COMMENT="## ⚠ shadow Failed
\`\`\`
${OUTPUT}
\`\`\`
"
        report_pull_request_comment
    fi
}

# check_staticcheck is excute "staticcheck" and generate ${COMMENT} and ${SUCCESS}
check_staticcheck() {
    echo 'run staticcheck checks'
    go get -u honnef.co/go/tools/cmd/staticcheck && go mod tidy

    set +e
    OUTPUT=$(sh -c "staticcheck ${FLAGS} ./... $*" 2>&1)
    SUCCESS=$?

    set -e
    if [ ${SUCCESS} -eq 0 ]; then
        echo '...passed'
        return
    fi

    echo "...failed ${SUCCESS}"
    if [ "${REPORT_COMMENT}" = "true" ]; then
        COMMENT="## ⚠ staticcheck Failed
\`\`\`
${OUTPUT}
\`\`\`

[Checks Document](https://staticcheck.io/docs/checks)
"
        report_pull_request_comment
    fi
}

# check_vet is excute "go vet" and generate ${COMMENT} and ${SUCCESS}
check_vet() {
    echo 'run vet checks'
    set +e
    OUTPUT=$(sh -c "go vet ${FLAGS} ./... $*" 2>&1)
    SUCCESS=$?

    set -e
    if [ ${SUCCESS} -eq 0 ]; then
        echo '...passed'
        return
    fi

    echo "...failed ${SUCCESS}"
    if [ "${REPORT_COMMENT}" = "true" ]; then
        COMMENT="## ⚠ vet Failed
\`\`\`
${OUTPUT}
\`\`\`
"
        report_pull_request_comment
    fi
}

assert_success() {
    if [ ${SUCCESS} -ne 0 ]; then
        exit ${SUCCESS}
    fi
}

# ------------------------
#  Main Flow
# ------------------------

case ${RUN} in
    "errcheck" )
        mod_download
        check_errcheck
        ;;
    "fmt" )
        check_fmt
        ;;
    "imports" )
        check_imports
        ;;
    "lint" )
        check_lint
        ;;
    "sec" )
        mod_download
        check_sec
        ;;
    "shadow" )
        mod_download
        check_shadow
        ;;
    "staticcheck" )
        mod_download
        check_staticcheck
        ;;
    "vet" )
        mod_download
        check_vet
        ;;
    * )
        mod_download
        check_errcheck
        assert_success
        check_fmt
        assert_success
        check_imports
        assert_success
        check_shadow
        assert_success
        check_staticcheck
        assert_success
        check_vet
        assert_success
        check_sec
        ;;
esac

exit ${SUCCESS}
