import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_interface/src/app/constants.dart';
import 'package:provider/provider.dart';

import '../controllers/social_controller.dart';
import '../widgets/social_user_card.dart';
import '../widgets/social_user_profile_popup.dart';

class FollowersTab extends StatelessWidget {
	const FollowersTab({super.key});

	@override
	Widget build(BuildContext context) {
		return Consumer<SocialController>(
			builder: (context, controller, _) {
				final users = controller.followers;
				final hasQuery = controller.followersQuery.trim().isNotEmpty;

				if (controller.isLoading && !controller.hasLoaded) {
					return const Center(child: CircularProgressIndicator());
				}

				return Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						_SocialSearchField(
							hintText: 'Search followers...',
							value: controller.followersQuery,
							onChanged: controller.setFollowersQuery,
						),
						const SizedBox(height: 16),
						Text(
							'${controller.followerCount} FOLLOWERS',
							style: GoogleFonts.montserrat(
								color: AppColors.textSecondary,
								fontSize: 12,
								fontWeight: FontWeight.w700,
								letterSpacing: 1.2,
							),
						),
						const SizedBox(height: 12),
						Expanded(
							child: controller.error != null && users.isEmpty
									? _ErrorState(
											text: controller.error!,
											onRetry: () => controller.load(force: true),
									  )
									: users.isEmpty
									? _EmptyState(
											text: hasQuery
													? 'No followers match your search.'
													: 'You have no followers.',
									  )
									: ListView.builder(
											itemCount: users.length,
											itemBuilder: (context, index) {
												final user = users[index];

												return SocialUserCard(
													user: user,
													actionLabel: user.iFollow ? 'Following' : 'Follow Back',
													highlightAction: !user.iFollow,
													onActionPressed: () {
														if (user.iFollow) {
															controller.unfollow(user.id);
															return;
														}
														controller.follow(user.id);
													},
																	onCardTap: () => showSocialUserProfilePopup(
																		context: context,
																		user: user,
																		onPrimaryAction: () {
																			if (user.iFollow) {
																				controller.unfollow(user.id);
																				return;
																			}
																			controller.follow(user.id);
																		},
																	),
												);
											},
										),
						),
					],
				);
			},
		);
	}
}

class _SocialSearchField extends StatelessWidget {
	const _SocialSearchField({
		required this.hintText,
		required this.value,
		required this.onChanged,
	});

	final String hintText;
	final String value;
	final ValueChanged<String> onChanged;

	@override
	Widget build(BuildContext context) {
		return Container(
			decoration: BoxDecoration(
				color: const Color(0x991E293B),
				borderRadius: BorderRadius.circular(12),
			),
			child: TextFormField(
				initialValue: value,
				onChanged: onChanged,
				style: GoogleFonts.montserrat(color: Colors.white),
				decoration: InputDecoration(
					isDense: true,
					contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
					border: InputBorder.none,
					hintText: hintText,
					hintStyle: GoogleFonts.montserrat(
						color: const Color(0xFF64748B),
						fontSize: 14,
						fontWeight: FontWeight.w400,
					),
					prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B), size: 20),
				),
			),
		);
	}
}

class _EmptyState extends StatelessWidget {
	const _EmptyState({required this.text});

	final String text;

	@override
	Widget build(BuildContext context) {
		return Center(
			child: Text(
				text,
				style: GoogleFonts.montserrat(
					color: AppColors.textSecondary,
					fontSize: 14,
					fontWeight: FontWeight.w600,
				),
			),
		);
	}
}

class _ErrorState extends StatelessWidget {
	const _ErrorState({required this.text, required this.onRetry});

	final String text;
	final VoidCallback onRetry;

	@override
	Widget build(BuildContext context) {
		return Center(
			child: Column(
				mainAxisSize: MainAxisSize.min,
				children: [
					Text(
						text,
						textAlign: TextAlign.center,
						style: GoogleFonts.montserrat(
							color: AppColors.textSecondary,
							fontSize: 14,
							fontWeight: FontWeight.w600,
						),
					),
					const SizedBox(height: 12),
					OutlinedButton(
						onPressed: onRetry,
						child: const Text('Retry'),
					),
				],
			),
		);
	}
}
