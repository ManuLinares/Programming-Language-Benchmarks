module app;
import libc, std::io;


struct TreeNode
{
	TreeNode* left;
	TreeNode* right;
}

fn TreeNode* create_tree(int depth)
{
	return mem::tnew(TreeNode, depth <= 0 ? {} : { create_tree(depth - 1), create_tree(depth - 1) });
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
		int arg_depth = args[1].to_int()!!;
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
	@pool()
	{
		TreeNode* stretch_tree = create_tree(stretch_depth);
		io::printfn("stretch tree of depth %d\t check: %d", stretch_depth, compute_tree_checksum(stretch_tree));
	};
	TreeNode* long_lived_tree = create_tree(max_depth);
	for (int depth = min_depth; depth <= max_depth; depth += 2)
	{
		int iterations = 1 << (max_depth - depth + min_depth);
		int checksum = 0;
		for (int i = 0; i < iterations; i++) @pool()
		{
			TreeNode* tree = create_tree(depth);
			checksum += compute_tree_checksum(tree);
		};
		io::printfn("%d\t trees of depth %d\t check: %d", iterations, depth, checksum);
	}

	io::printfn("long lived tree of depth %d\t check: %d", max_depth, compute_tree_checksum(long_lived_tree));
	return 0;
}
