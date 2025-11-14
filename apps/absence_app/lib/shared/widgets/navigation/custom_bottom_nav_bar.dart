import 'package:flutter/material.dart';

/// Item de navegação customizado
class NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// Bottom Navigation Bar customizada com efeitos elegantes
class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<NavItem> items;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.onSurface.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          items.length,
          (index) => _NavBarItem(
            item: items[index],
            isSelected: currentIndex == index,
            onTap: () => onTap(index),
            colorScheme: colorScheme,
          ),
        ),
      ),
    );
  }
}

/// Item individual da navegação com efeitos de hover
class _NavBarItem extends StatefulWidget {
  final NavItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _NavBarItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  State<_NavBarItem> createState() => _NavBarItemState();
}

class _NavBarItemState extends State<_NavBarItem>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 0.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isSelected;

    return MouseRegion(
      onEnter: (_) {
        if (!isActive) {
          setState(() => _isHovered = true);
          _controller.forward();
        }
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? widget.colorScheme.onSurface.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ícone com hover effect
              Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Glow maior ao hover (usando Positioned para não afetar layout)
                  if (_isHovered && !isActive)
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _fadeAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: 1.7, // Glow 70% maior que o ícone
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: widget.colorScheme.onSurface
                                    .withValues(alpha: _fadeAnimation.value),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  
                  // Ícone (tamanho fixo)
                  Icon(
                    isActive ? widget.item.activeIcon : widget.item.icon,
                    key: ValueKey(isActive),
                    color: isActive
                        ? widget.colorScheme.onSurface
                        : widget.colorScheme.onSurface.withValues(
                            alpha: _isHovered ? 0.7 : 0.5,
                          ),
                    size: 28,
                  ),
                ],
              ),
              
              // Label animado (aparece somente quando selecionado)
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: isActive
                    ? Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: widget.colorScheme.onSurface,
                            letterSpacing: 0.3,
                          ),
                          child: Text(widget.item.label),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
