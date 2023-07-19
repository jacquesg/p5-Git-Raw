#include "clar_libgit2.h"

#include "repository.h"

#ifdef GIT_EXPERIMENTAL_SHA256
static git_repository *g_repo;
#endif

void test_object_lookup256__initialize(void)
{
#ifdef GIT_EXPERIMENTAL_SHA256
	g_repo = cl_git_sandbox_init("testrepo_256.git");
#endif
}

void test_object_lookup256__cleanup(void)
{
#ifdef GIT_EXPERIMENTAL_SHA256
	cl_git_sandbox_cleanup();
#endif
}

void test_object_lookup256__lookup_wrong_type_returns_enotfound(void)
{
#ifndef GIT_EXPERIMENTAL_SHA256
	cl_skip();
#else
	const char *commit = "4d46d9719e425ef2dfb5bfba098d0b62e21b2b92d0731892eef70db0870e3744";
	git_oid oid;
	git_object *object;

	cl_git_pass(git_oid__fromstr(&oid, commit, GIT_OID_SHA256));
	cl_assert_equal_i(
		GIT_ENOTFOUND, git_object_lookup(&object, g_repo, &oid, GIT_OBJECT_TAG));
#endif
}

void test_object_lookup256__lookup_nonexisting_returns_enotfound(void)
{
#ifndef GIT_EXPERIMENTAL_SHA256
	cl_skip();
#else
	const char *unknown = "deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef";
	git_oid oid;
	git_object *object;

	cl_git_pass(git_oid__fromstr(&oid, unknown, GIT_OID_SHA256));
	cl_assert_equal_i(
		GIT_ENOTFOUND, git_object_lookup(&object, g_repo, &oid, GIT_OBJECT_ANY));
#endif
}

void test_object_lookup256__lookup_wrong_type_by_abbreviated_id_returns_enotfound(void)
{
#ifndef GIT_EXPERIMENTAL_SHA256
	cl_skip();
#else
	const char *commit = "4d46d97";
	git_oid oid;
	git_object *object;

	cl_git_pass(git_oid__fromstrn(&oid, commit, strlen(commit), GIT_OID_SHA256));
	cl_assert_equal_i(
		GIT_ENOTFOUND, git_object_lookup_prefix(&object, g_repo, &oid, strlen(commit), GIT_OBJECT_TAG));
#endif
}

void test_object_lookup256__lookup_wrong_type_eventually_returns_enotfound(void)
{
#ifndef GIT_EXPERIMENTAL_SHA256
	cl_skip();
#else
	const char *commit = "4d46d9719e425ef2dfb5bfba098d0b62e21b2b92d0731892eef70db0870e3744";
	git_oid oid;
	git_object *object;

	cl_git_pass(git_oid__fromstr(&oid, commit, GIT_OID_SHA256));

	cl_git_pass(git_object_lookup(&object, g_repo, &oid, GIT_OBJECT_COMMIT));
	git_object_free(object);

	cl_assert_equal_i(
		GIT_ENOTFOUND, git_object_lookup(&object, g_repo, &oid, GIT_OBJECT_TAG));
#endif
}

void test_object_lookup256__lookup_corrupt_object_returns_error(void)
{
#ifndef GIT_EXPERIMENTAL_SHA256
	cl_skip();
#else
	const char *commit = "5ca8959deb2b8327458e0344523eb1ddeeef4bce03e35864640b452f84d26848",
	      *file = "objects/5c/a8959deb2b8327458e0344523eb1ddeeef4bce03e35864640b452f84d26848";
	git_str path = GIT_STR_INIT, contents = GIT_STR_INIT;
	git_oid oid;
	git_object *object;
	size_t i;

	cl_git_pass(git_oid__fromstr(&oid, commit, GIT_OID_SHA256));
	cl_git_pass(git_str_joinpath(&path, git_repository_path(g_repo), file));
	cl_git_pass(git_futils_readbuffer(&contents, path.ptr));

	/* Corrupt and try to read the object */
	for (i = 0; i < contents.size; i++) {
		contents.ptr[i] ^= 0x1;
		cl_git_pass(git_futils_writebuffer(&contents, path.ptr, O_RDWR, 0644));
		cl_git_fail(git_object_lookup(&object, g_repo, &oid, GIT_OBJECT_COMMIT));
		contents.ptr[i] ^= 0x1;
	}

	/* Restore original content and assert we can read the object */
	cl_git_pass(git_futils_writebuffer(&contents, path.ptr, O_RDWR, 0644));
	cl_git_pass(git_object_lookup(&object, g_repo, &oid, GIT_OBJECT_COMMIT));

	git_object_free(object);
	git_str_dispose(&path);
	git_str_dispose(&contents);
#endif
}

void test_object_lookup256__lookup_object_with_wrong_hash_returns_error(void)
{
#ifndef GIT_EXPERIMENTAL_SHA256
	cl_skip();
#else
	const char *oldloose = "objects/5c/a8959deb2b8327458e0344523eb1ddeeef4bce03e35864640b452f84d26848",
	      *newloose = "objects/5c/a8959deb2b8327458e0344523eb1ddeeef4bce03e35864640b452f84d26840",
	      *commit = "5ca8959deb2b8327458e0344523eb1ddeeef4bce03e35864640b452f84d26840";

	git_str oldpath = GIT_STR_INIT, newpath = GIT_STR_INIT;
	git_object *object;
	git_oid oid;

	cl_git_pass(git_oid__fromstr(&oid, commit, GIT_OID_SHA256));

	/* Copy object to another location with wrong hash */
	cl_git_pass(git_str_joinpath(&oldpath, git_repository_path(g_repo), oldloose));
	cl_git_pass(git_str_joinpath(&newpath, git_repository_path(g_repo), newloose));
	cl_git_pass(git_futils_cp(oldpath.ptr, newpath.ptr, 0644));

	/* Verify that lookup fails due to a hashsum mismatch */
	cl_git_fail_with(GIT_EMISMATCH, git_object_lookup(&object, g_repo, &oid, GIT_OBJECT_COMMIT));

	/* Disable verification and try again */
	cl_git_pass(git_libgit2_opts(GIT_OPT_ENABLE_STRICT_HASH_VERIFICATION, 0));
	cl_git_pass(git_object_lookup(&object, g_repo, &oid, GIT_OBJECT_COMMIT));
	cl_git_pass(git_libgit2_opts(GIT_OPT_ENABLE_STRICT_HASH_VERIFICATION, 1));

	git_object_free(object);
	git_str_dispose(&oldpath);
	git_str_dispose(&newpath);
#endif
}
