# open questions

consolidated questions requiring user clarification before implementation.

---

## answered/resolved

### Q1: base os choice ✅
**feature**: base-image
**answer**: debian/ubuntu (broader tool compatibility)

### Q2: architecture requirements ✅
**feature**: base-image
**answer**: amd64 + arm64 multi-arch (works on intel/amd and apple silicon)

### Q3: ruby version for rails image ✅
**feature**: child-images
**answer**: track latest stable ruby (e.g., 3.3.x)

### Q4: ruby lsp inclusion ✅
**feature**: child-images
**answer**: yes, include ruby lsp

### Q5: container image naming ✅
**feature**: build-ci
**answer**: variant tags - `ghcr.io/schpet/cracked:base`, `ghcr.io/schpet/cracked:deno`, etc.

### Q6: tools directory location ✅
**feature**: deno-tools
**answer**: ~/tools (in root user's home directory)

### Q7: dotfiles installation method ✅
**feature**: dotfiles
**answer**: run `install.sh` script from the dotfiles repo (not direct stow invocation)

### Q8: jj author details for verification ✅
**feature**: dotfiles
**answer**: verify email is `code@schpet.com`

### Q9: rust cargo plugins ✅
**feature**: child-images
**answer**: yes, include common tools: clippy, rustfmt, cargo-watch, cargo-edit

### Q10: onboarding approach ✅
**feature**: onboarding
**answer**: markdown checklist (simpler, always works)

### Q11: container user ✅
**feature**: base-image, dotfiles
**answer**: root user (simpler for dev containers)

### Q12: dockerfile naming convention ✅
**feature**: build-ci
**answer**: use Dockerfile convention (more common)
**default applied**: Dockerfile, Dockerfile.deno, Dockerfile.rust, Dockerfile.rails

### Q13: ci trigger strategy ✅
**feature**: build-ci
**answer**: tags + manual dispatch (matches easy-bead-oven reference)
**default applied**: trigger on `container-v*` tags and workflow_dispatch

### Q14: version pinning strategy ✅
**feature**: base-image
**answer**: pin base os, use latest for tools
**default applied**: reasonable balance of reproducibility and freshness

---

*all questions resolved - ready for issue generation*
