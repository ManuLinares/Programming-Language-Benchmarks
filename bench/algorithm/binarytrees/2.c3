module app;
import libc;
import std::io;

struct TreeNode
{
	TreeNode* left;
	TreeNode* right;
}

fn TreeNode* create_tree(int depth)
{
	TreeNode* root = (TreeNode*)libc::calloc(1, TreeNode.sizeof);
	if (depth > 0)
	{
		root.left = create_tree(depth - 1);
		root.right = create_tree(depth - 1);
	}
	return root;
}

fn void free_tree(TreeNode* root)
{
	if (root == null) return;
	if (root.left != null)
	{
		free_tree(root.left);
	}
	if (root.right != null)
	{
		free_tree(root.right);
	}
	libc::free(root);
}

fn int compute_tree_checksum(TreeNode* root)
{
	if (root.left != null && root.right != null)
	{
		return compute_tree_checksum(root.left) + compute_tree_checksum(root.right) + 1;
	}
	return 1;
}

fn int main(String[] args)
{
	int min_depth = 4;
	int max_depth = 10;
	if (args.len >= 2)
	{
		int arg_depth = libc::atoi((char*)args[1].ptr);
		if (arg_depth > min_depth + 2)
		{
			max_depth = arg_depth;
		}
		else
		{
			max_depth = min_depth + 2;
		}
	}

	int stretch_depth = max_depth + 1;
	TreeNode* stretch_tree = create_tree(stretch_depth);
	io::printfn("stretch tree of depth %d\t check: %d", stretch_depth, compute_tree_checksum(stretch_tree));
	free_tree(stretch_tree);

	TreeNode* long_lived_tree = create_tree(max_depth);

	for (int depth = min_depth; depth <= max_depth; depth += 2)
	{
		int iterations = 1 << (max_depth - depth + min_depth);
		int checksum = 0;

		for (int i = 0; i < iterations; i++)
		{
			TreeNode* tree = create_tree(depth);
			checksum += compute_tree_checksum(tree);
			free_tree(tree);
		}

		io::printfn("%d\t trees of depth %d\t check: %d", iterations, depth, checksum);
	}

	io::printfn("long lived tree of depth %d\t check: %d", max_depth, compute_tree_checksum(long_lived_tree));
	free_tree(long_lived_tree);

	return 0;
}